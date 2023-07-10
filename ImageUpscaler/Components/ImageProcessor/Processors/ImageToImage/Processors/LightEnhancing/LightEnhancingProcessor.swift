//
//  LightEnhancingProcessor.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 10.07.2023.
//

import CoreML
import Vision

final class LightEnhancingProcessor: ImageToImageProcessor {
    init() {
        super.init {
            let configuration = MLModelConfiguration()
            guard
                let coreMLModel = try? Zero_DCE(configuration: configuration),
                let visionModel = try? VNCoreMLModel(for: coreMLModel.model)
            else {
                return nil
            }
            
            return visionModel
        }
    }
}
