//
//  UpscaleProcessor.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 23.06.2023.
//

import SwiftUI
import Vision
import CoreML

final class UpscalingProcessor: RegularMLModelProcessor {
    init(manager: ImageProcessingManager) throws {
        let config = MLModelConfiguration()
        guard
            let coreMLModel = try? RealsrGAN(configuration: config),
            let visionModel = try? VNCoreMLModel(for: coreMLModel.model)
        else {
            throw ImageProcessingError.modelLoadingError
        }
        
        try super.init(visionModel: visionModel)
    }
}

extension UpscalingProcessor: ImageProcessing { }
