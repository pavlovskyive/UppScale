//
//  ProcessingType+Model.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 15.07.2023.
//

import Foundation
import CoreML
import Vision

extension ProcessingType {
    /// Loads the Core ML model associated with the processing type.
    func loadModel() throws -> VNCoreMLModel {
        switch self {
        case .upscaling:
            return try Self.loadUpscalingModel()
        case .lightEnhancing:
            return try Self.loadLightEnhancingModel()
        }
    }
}

private extension ProcessingType {
    /// Loads the Core ML model for upscaling.
    static func loadUpscalingModel() throws -> VNCoreMLModel {
        let configuration = MLModelConfiguration()
        let coreMLModel = try Upscaler(configuration: configuration)
        let visionModel = try VNCoreMLModel(for: coreMLModel.model)
                        
        return visionModel
    }
    
    /// Loads the Core ML model for light enhancing.
    static func loadLightEnhancingModel() throws -> VNCoreMLModel {
        let configuration = MLModelConfiguration()
        let coreMLModel = try LightEnhancer(configuration: configuration)
        let visionModel = try VNCoreMLModel(for: coreMLModel.model)
                        
        return visionModel
    }
}
