//
//  LightEnhancingProcessor.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 10.07.2023.
//

import CoreML
import Vision

import class SwiftUI.UIImage

final class LightEnhancingProcessor: ImageToImageProcessor {
    private let upscalingProcessor: UpscalingProcessor?
    
    init(upscalingProcessor: UpscalingProcessor? = nil) {
        self.upscalingProcessor = upscalingProcessor
        super.init {
            let configuration = MLModelConfiguration()
            let coreMLModel = try Zero_DCE(configuration: configuration)
            let visionModel = try VNCoreMLModel(for: coreMLModel.model)
            
            return visionModel
        }
    }
}
