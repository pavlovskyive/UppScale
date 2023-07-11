//
//  UpscalingProcessor.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 20.06.2023.
//

import SwiftUI
import Vision
import CoreML

class UpscalingProcessor {
    private var model: VNCoreMLModel?
    
    func preProcess(image: UIImage) throws -> CIImage {
        guard let cgImage = image.cgImage // needed to translate uiimage into ciimage
        else {
            throw UpscalingError.invalidImageData
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        let inputMaxDimension = max(ciImage.extent.width, ciImage.extent.height)
        let squareCanvasSize = CGSize(width: inputMaxDimension, height: inputMaxDimension)
        
        let context = CIContext()
        let blackCanvas = CIImage(color: CIColor.black)
            .cropped(to: CGRect(origin: .zero, size: squareCanvasSize))
        let squaredCIImage = ciImage.composited(over: blackCanvas)
        
        return squaredCIImage
    }
    
    func postProcess(
        ciImage: UIImage,
        aspectRatio: Int,
        orientation: UIImage.Orientation
    ) async throws -> UIImage {
        
    }
}

extension UpscalingProcessor: MLImageProcessable {
    func loadModel() async throws {
        let config = MLModelConfiguration()
        guard
            let coreMLModel = try? RealsrGAN(configuration: config),
            let visionModel = try? VNCoreMLModel(for: coreMLModel.model)
        else {
            throw MLImageProcessingError.modelLoadingError
        }
        
        self.model = visionModel
    }
    
    func processImage(_ uiImage: UIImage) async throws -> Image {
        
    }
}
