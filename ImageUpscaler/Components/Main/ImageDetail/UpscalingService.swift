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
        
        let outputImage = try await processTile(inputCIImage)
        
        print("DEBUG:", "resulting size:", outputImage.extent.size)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            throw UpscalingError.imageConversionError
        }

        let uiImage = UIImage(cgImage: cgImage)
        let finalImage = Image(uiImage: uiImage)
        
        return finalImage
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
                
                let outputImageSize = CGSize(
                    width: CVPixelBufferGetWidth(outputPixelBuffer),
                    height: CVPixelBufferGetHeight(outputPixelBuffer)
                )
                
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
    
    case tempError // TODO: remove after debugging
}
