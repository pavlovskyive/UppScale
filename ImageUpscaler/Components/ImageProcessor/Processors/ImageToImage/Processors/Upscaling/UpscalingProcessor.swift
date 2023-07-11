//
//  UpscalingProcessor.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 10.07.2023.
//

import CoreML
import Vision

final class UpscalingProcessor: ImageToImageProcessor {
    init() {
        super.init {
            let configuration = MLModelConfiguration()
            let coreMLModel = try RealesrGAN(configuration: configuration)
            let visionModel = try VNCoreMLModel(for: coreMLModel.model)

            return visionModel
        }
    }
}
