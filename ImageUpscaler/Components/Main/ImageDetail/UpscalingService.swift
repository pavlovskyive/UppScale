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
        let blackCanvas = CIImage(color: CIColor.black).cropped(to: CGRect(origin: .zero, size: squareCanvasSize))
        let squareInputCIImage = inputCIImage.composited(over: blackCanvas)
        
        let outputCIImage = try await processTile(squareInputCIImage)
        
        let outputMaxDimension = max(outputCIImage.extent.width, outputCIImage.extent.height)
        let scalingFactor = outputMaxDimension / inputMaxDimension
        
        let outputSize = inputCIImage.extent.size.applying(
            CGAffineTransform(scaleX: scalingFactor, y: scalingFactor)
        )
        
        let croppedCIImage = outputCIImage.cropped(to: CGRect(origin: .zero, size: outputSize))
        let orientedCIImage = croppedCIImage.oriented(
            forExifOrientation: inputUIImage.imageOrientation.exifOrientation
        )
        
        guard let outputCGImage = context.createCGImage(
            orientedCIImage,
            from: orientedCIImage.extent
        ) else {
            throw UpscalingError.imageConversionError
        }
        
        let outputUIImage = UIImage(cgImage: outputCGImage)
        
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
    case invalidImageData
    case tileProcessingError
    case processingError
    case compositeImageCreationError
    case imageConversionError
    
    case tooBig
    
    case tempError // TODO: remove after debugging
}

private extension UIImage.Orientation {
    var exifOrientation: Int32 {
        switch self {
        case .up: return 1
        case .down: return 3
        case .left: return 8
        case .right: return 6
        case .upMirrored: return 2
        case .downMirrored: return 4
        case .leftMirrored: return 5
        case .rightMirrored: return 7
        @unknown default: return 1
        }
    }
}
