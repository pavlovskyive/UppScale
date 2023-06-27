//
//  UpscaleProcessor.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 23.06.2023.
//

import SwiftUI
import Vision
import CoreML

final class UpscalingProcessor: ImageProcessing {
    struct Parameters {
        let data: Data
        let rect: CGRect?
    }
    
    let model: VNCoreMLModel
    
    init() throws {
        let config = MLModelConfiguration()
        guard
            let coreMLModel = try? RealsrGAN(configuration: config),
            let visionModel = try? VNCoreMLModel(for: coreMLModel.model)
        else {
            throw ImageProcessingError.modelLoadingError
        }
        
        self.model = visionModel
    }
    
    func processImage(parameters: Parameters) async throws -> UIImage {
        guard
            let inputUIImage = UIImage(data: parameters.data), // needed for metadata
            let inputCGImage = inputUIImage.cgImage // needed to translate uiimage into ciimage
        else {
            throw ImageProcessingError.invalidParametersData // TODO: change
        }
        
        let inputCIImage = CIImage(cgImage: inputCGImage)
        
        let inputMaxDimension = max(inputCIImage.extent.width, inputCIImage.extent.height)
        let squareCanvasSize = CGSize(width: inputMaxDimension, height: inputMaxDimension)
        
        let context = CIContext()
        let blackCanvas = CIImage(color: CIColor.black)
            .cropped(to: CGRect(origin: .zero, size: squareCanvasSize))
        let squareInputCIImage = inputCIImage.composited(over: blackCanvas)
        
        let outputCIImage = try await process(squareInputCIImage)
        
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
            throw ImageProcessingError.processingError // TODO: change
        }

        let outputUIImage = UIImage(
            cgImage: outputCGImage,
            scale: 1,
            orientation: inputUIImage.imageOrientation
        )
        
        return outputUIImage
    }
}

private extension UpscalingProcessor {
    private func process(_ inputCIImage: CIImage) async throws -> CIImage {
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
                    continuation.resume(throwing: ImageProcessingError.processingError)
                    
                    return
                }
                
                let ciImage = CIImage(cvPixelBuffer: outputPixelBuffer)
                
                continuation.resume(returning: ciImage)
            }
            
            let handler = VNImageRequestHandler(ciImage: inputCIImage)
            try? handler.perform([request]) // errors will be handled in continuation
        }
    }
}
