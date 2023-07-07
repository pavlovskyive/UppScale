//
//  LightEnhancementProcessor.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 27.06.2023.
//

import SwiftUI
import Vision
import CoreML

final class LightEnhancementProcessor: RegularMLModelProcessor {
    let manager: ImageProcessingManager
    
    init(manager: ImageProcessingManager) throws {
        let config = MLModelConfiguration()
        guard
            let coreMLModel = try? Zero_DCE(configuration: config),
            let visionModel = try? VNCoreMLModel(for: coreMLModel.model)
        else {
            throw ImageProcessingError.modelLoadingError
        }
        
        self.manager = manager
        try super.init(visionModel: visionModel)
    }

    // Strong link to upscaling processor.
    // This is needed because most models
    // process output is 512x512, so we can use upscaling processor to improve
    // resulting image quality
    override func processImage(parameters: Parameters) async throws -> UIImage {
        let processedUIImage = try await super.processImage(parameters: parameters)
        
        return try await manager.processImage(
            type: UpscalingProcessor.self,
            parameters: UpscalingProcessor.Parameters(uiImage: processedUIImage)
        )
    }
}

extension LightEnhancementProcessor: ImageProcessing { }
