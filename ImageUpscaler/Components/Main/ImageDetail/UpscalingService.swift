//
//  ImageUpscalerApp.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 17.06.2023.
//

import SwiftUI
import CoreML
import Vision

class UpscalingService: ObservableObject {
    private let model: VNCoreMLModel
    @Published var currentLog = "" // TODO: REMOVE LATER
    @Published var isBusy = false
    
    let processingQueue = DispatchQueue(label: "tile-processing", attributes: .concurrent)
    
    init() {
        let config = MLModelConfiguration()
        guard
            let coreMLModel = try? RealsrGAN(configuration: config),
            let visionModel = try? VNCoreMLModel(for: coreMLModel.model)
        else {
            fatalError("Cannot load model")
        }
        
        self.model = visionModel
    }
    
    func upscaleImage(imageData inputImageData: Data) async -> Result<Image, Error> {
        DispatchQueue.main.async { [weak self] in
            self?.isBusy = true
        }
        
        defer {
            DispatchQueue.main.async { [weak self] in
                self?.isBusy = false
            }
        }
        
        do {
            let image = try await processImage(inputImageData)
            
            return .success(image)
        } catch {
            return .failure(error)
        }
    }
}

private extension UpscalingService {
    func processImage(_ data: Data) async throws -> Image {
        guard let inputCIImage = CIImage(data: data) else {
            throw UpscalingError.invalidImageData
        }
        
        print("DEBUG:", "initial size:", inputCIImage.extent.size)
        
        let standartTileSize = 512
        let outputTileSize = 2048
        
        let tileDimention = min(
            CGFloat(standartTileSize),
            inputCIImage.extent.width,
            inputCIImage.extent.height
        )
        
        let tileSize = CGSize(width: tileDimention, height: tileDimention)
        let numTilesX = Int(ceil(inputCIImage.extent.size.width / tileSize.width))
        let numTilesY = Int(ceil(inputCIImage.extent.size.height / tileSize.height))
        
        print("DEBUG:", "number of tiles", "\(numTilesX)x\(numTilesY)", " = \(numTilesX * numTilesY)")
        
        guard numTilesX * numTilesY < 25 else {
            throw UpscalingError.tooBig
        }
        
        var composedImage = CIImage(color: .clear).cropped(
            to: CGRect(
                origin: .zero,
                size: CGSize(
                    width: numTilesX * outputTileSize,
                    height: numTilesY * outputTileSize
                )
            )
        )
        
        print(composedImage.extent.size)
        
        try await withThrowingTaskGroup(of: CIImage.self) { group in
            for tileX in 0..<numTilesX {
                for tileY in 0..<numTilesY {
                    let tileIndex = tileX * numTilesY + tileY
                    print("Processing: \(tileIndex + 1)")
                    
                    let tileRect = CGRect(
                        x: tileX * Int(tileSize.width),
                        y: tileY * Int(tileSize.height),
                        width: Int(tileSize.width),
                        height: Int(tileSize.height)
                    )
                    
                    group.addTask { [weak self] in
                        guard let self else {
                            throw UpscalingError.tileProcessingError
                        }
                        
                        let tileCanvas = CIImage(color: .clear).cropped(to: tileRect)
                        var tileImage = inputCIImage.cropped(to: tileRect)
                        
                        tileImage = tileImage.composited(over: tileCanvas)
                        
                        var processedTile = try await self.processTile(tileImage)
                        
                        let transform = CGAffineTransform(
                            translationX: CGFloat(tileX * outputTileSize),
                            y: CGFloat(tileY * outputTileSize)
                        )
                        
                        processedTile = processedTile.transformed(by: transform)
                        
                        print("Processed: \(tileIndex + 1)")
                        
                        return (processedTile)
                    }
                }
            }
            
            for try await result in group {
                composedImage = result.composited(over: composedImage)
            }
        }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(
            composedImage, from: composedImage.extent
        ) else {
            throw UpscalingError.imageConversionError
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        
        return Image(uiImage: uiImage)
    }
    
    private func processTile(_ inputCIImage: CIImage) async throws -> CIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)

                    return
                }
                
                guard
                    let results = request.results as? [VNPixelBufferObservation],
                    let outputPixelBuffer = results.first?.pixelBuffer
                else {
                    continuation.resume(throwing: UpscalingError.processingError)

                    return
                }
                
                continuation.resume(returning: CIImage(cvPixelBuffer: outputPixelBuffer))
            }
            
            do {
                let handler = VNImageRequestHandler(ciImage: inputCIImage)
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

enum UpscalingError: Error {
    case invalidImageData
    case tileProcessingError
    case processingError
    case compositeImageCreationError
    case imageConversionError
    
    case tooBig
    
    case tempError // TODO: remove after debugging
}
