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
        // NOTE: direct CIImage(data: Data) creation omits metadata.
        guard
            let inputUIImage = UIImage(data: data), // needed for metadata
            let inputCGImage = inputUIImage.cgImage // needed to translate uiimage into ciimage
        else {
            throw UpscalingError.invalidImageData
        }
        
        let inputCIImage = CIImage(cgImage: inputCGImage)
        
        let inputMaxDimension = max(inputCIImage.extent.width, inputCIImage.extent.height)
        let squareCanvasSize = CGSize(width: inputMaxDimension, height: inputMaxDimension)
        
        let context = CIContext()
        let blackCanvas = CIImage(color: CIColor.black)
            .cropped(to: CGRect(origin: .zero, size: squareCanvasSize))
        let squareInputCIImage = inputCIImage.composited(over: blackCanvas)
        
        let outputCIImage = try await processTile(squareInputCIImage)
        
        let outputMaxDimension = max(outputCIImage.extent.width, outputCIImage.extent.height)
        let scalingFactor = outputMaxDimension / inputMaxDimension
        
        let outputSize = inputCIImage.extent.size.applying(
            CGAffineTransform(scaleX: scalingFactor, y: scalingFactor)
        )
        
        let croppedCIImage = outputCIImage.cropped(to: CGRect(origin: .zero, size: outputSize))
        
        guard let outputCGImage = context.createCGImage(
            croppedCIImage,
            from: croppedCIImage.extent
        ) else {
            throw UpscalingError.imageConversionError
        }

        let outputUIImage = UIImage(
            cgImage: outputCGImage,
            scale: 1,
            orientation: inputUIImage.imageOrientation
        )
        
        return Image(uiImage: outputUIImage)
    }
    
    private func processTile(_ inputCIImage: CIImage) async throws -> CIImage {
        try await withCheckedThrowingContinuation { continuation in
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
                
                let ciImage = CIImage(cvPixelBuffer: outputPixelBuffer)
                
                continuation.resume(returning: ciImage)
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
    case processingError
    case invalidImageData
    case imageConversionError
}