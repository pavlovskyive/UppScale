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
    
    func upscaleImage(
        imageData inputImageData: Data,
        tileSize: Int = 512
    ) async -> Result<Image, Error> {
        DispatchQueue.main.async { [weak self] in
            self?.isBusy = true
        }
        
        defer {
            DispatchQueue.main.async { [weak self] in
                self?.isBusy = false
            }
        }
        
        do {
            let image = try await processImage(inputImageData, inputTileSize: CGFloat(tileSize))

            return .success(image)
        } catch {
            return .failure(error)
        }
    }
}

private extension UpscalingService {
    func processImage(_ data: Data, inputTileSize: CGFloat) async throws -> Image {
        guard let inputCIImage = CIImage(data: data) else {
            throw UpscalingError.invalidImageData
        }
        
        print("DEBUG:", "initial size:", inputCIImage.extent.size)
        
        let outputTileSizeDimension = 2048.0
        
        let tileSizeDimension = min(
            inputTileSize,
            inputCIImage.extent.width,
            inputCIImage.extent.height
        )
        
        let initialTileFeathering = 10.0
        let outputTileFeathering = (outputTileSizeDimension / tileSizeDimension) * initialTileFeathering
        
        let tileSize = CGSize(
            width: tileSizeDimension,
            height: tileSizeDimension
        )
        
        let outputTileSize = CGSize(
            width: outputTileSizeDimension,
            height: outputTileSizeDimension
        )
        
        let numTilesX = Int(ceil(inputCIImage.extent.size.width / tileSize.width))
        let numTilesY = Int(ceil(inputCIImage.extent.size.height / tileSize.height))
        
        guard numTilesX * numTilesY < 25 else {
            throw UpscalingError.tooBig
        }
        
        // What part of result is image, and what is empty part.
        let widthResultRatio = inputCIImage.extent.width / (CGFloat(numTilesX) * tileSizeDimension)
        let heightResultRatio = inputCIImage.extent.height / (CGFloat(numTilesY) * tileSizeDimension)
        
        print("DEBUG:", "number of tiles", "\(numTilesX)x\(numTilesY)", " = \(numTilesX * numTilesY)")
        
        let processedTiles = try await processTiles(
            from: inputCIImage,
            numTilesX: numTilesX,
            numTilesY: numTilesY,
            tileSize: tileSize,
            tileFeathering: initialTileFeathering
        )
        
        let uiImage = try await combineTiles(
            numTilesX: numTilesX,
            numTilesY: numTilesY,
            tiles: processedTiles,
            tileSize: outputTileSize,
            feathering: outputTileFeathering
        )
        
        return Image(uiImage: uiImage)
    }
    
    private func combineTiles(
        numTilesX: Int,
        numTilesY: Int,
        tiles: [UIImage],
        tileSize: CGSize,
        feathering: CGFloat
    ) async throws -> UIImage {
        let canvasSize = CGSize(
            width: tileSize.width * CGFloat(numTilesX),
            height: tileSize.height * CGFloat(numTilesY)
        )
        
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        
        return try await withCheckedThrowingContinuation { continuation in
            let uiImage = renderer.image { context in
                context.cgContext.translateBy(x: 0, y: canvasSize.height)
                context.cgContext.scaleBy(x: 1, y: -1)
                
                
                for (index, tile) in tiles.enumerated() {
                    let tileX = index % numTilesX
                    let tileY = index / numTilesX

                    let featheredRect = CGRect(
                        x: max(tileSize.width * CGFloat(tileX) - feathering, 0),
                        y: max(tileSize.height * CGFloat(tileY) - feathering, 0),
                        width: tileSize.width,
                        height: tileSize.height
                    )

                    guard let cgImage = tile.cgImage else {
                        continuation.resume(throwing: UpscalingError.compositeImageCreationError)

                        return
                    }

                    guard index > 0 else {
                        context.cgContext.draw(cgImage, in: featheredRect)

                        continue
                    }

                    context.cgContext.saveGState()
                    context.cgContext.setAlpha(0.0)
                    context.cgContext.clip(to: featheredRect, mask: cgImage)
                    context.cgContext.setAlpha(1.0)
                    context.cgContext.setBlendMode(.normal)
                    context.cgContext.draw(cgImage, in: featheredRect)
                    context.cgContext.restoreGState()
                }
            }
            
            continuation.resume(returning: uiImage)
        }
    }
    
    private func processTiles(
        from ciImage: CIImage,
        numTilesX: Int,
        numTilesY: Int,
        tileSize: CGSize,
        tileFeathering: CGFloat
    ) async throws -> [UIImage] {
        var orderedProcessedTiles = [(Int, UIImage)]()
        let context = CIContext()
        
        try await withThrowingTaskGroup(of: (Int, UIImage).self) { group in
            for tileIndex in 0..<(numTilesX * numTilesY) {
                print("processing: \(tileIndex)")
                
                let tileX = tileIndex % numTilesX
                let tileY = tileIndex / numTilesX
                
                let tileRect = CGRect(
                    x: CGFloat(tileX) * tileSize.width,
                    y: CGFloat(tileY) * tileSize.height,
                    width: tileSize.width + tileFeathering,
                    height: tileSize.height + tileFeathering
                )
                
                group.addTask { [weak self] in
                    guard let self = self else {
                        throw UpscalingError.tileProcessingError
                    }
                    
                    // Adding empty space for incomplete tiles.
                    var tileImage = CIImage(color: .clear).cropped(to: tileRect)
                    tileImage = ciImage.cropped(to: tileRect).composited(over: tileImage)
                    
                    let processedTile = try await self.processTile(tileImage)
                    
                    guard let cgImage = context.createCGImage(
                        processedTile,
                        from: processedTile.extent
                    ) else {
                        throw UpscalingError.tileProcessingError
                    }
                    
                    print("processed: \(tileIndex)")
                    
                    return (tileIndex, UIImage(cgImage: cgImage))
                }
            }
            
            for try await result in group {
                orderedProcessedTiles.append(result)
            }
        }
        
        return orderedProcessedTiles.sorted(by: { $0.0 < $1.0 }).map(\.1)
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
