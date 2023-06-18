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
        
        // Calculate the desired output size while maintaining aspect ratio
        let aspectRatio = inputCIImage.extent.width / inputCIImage.extent.height
        let maxOutputSize = CGSize(width: 2048, height: 2048)
        let desiredOutputSize = CGSize(
            width: min(maxOutputSize.width, maxOutputSize.height * aspectRatio),
            height: min(maxOutputSize.height, maxOutputSize.width / aspectRatio)
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard
                    let results = request.results as? [VNPixelBufferObservation],
                    let outputImageBuffer = results.first?.pixelBuffer
                else {
                    continuation.resume(throwing: UpscalingError.processingError)
                    return
                }
                
                let outputCIImage = CIImage(cvPixelBuffer: outputImageBuffer)
                let context = CIContext()
                
                // Scale the output image to the desired size while maintaining aspect ratio
                let scaledOutputCIImage = outputCIImage.transformed(
                    by: CGAffineTransform(
                        scaleX: desiredOutputSize.width / outputCIImage.extent.width,
                        y: desiredOutputSize.height / outputCIImage.extent.height
                    )
                )
                
                guard let outputCGImage = context.createCGImage(
                    scaledOutputCIImage,
                    from: scaledOutputCIImage.extent
                ) else {
                    continuation.resume(throwing: UpscalingError.imageConversionError)
                    return
                }
                
                let uiImage = UIImage(cgImage: outputCGImage)
                
                continuation.resume(returning: Image(uiImage: uiImage))
            }
            
            let handler = VNImageRequestHandler(ciImage: inputCIImage)
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

enum UpscalingError: Error {
    case invalidImageData
    case processingError
    case imageConversionError
}
