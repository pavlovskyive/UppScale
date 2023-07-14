//
//  ProcessingModelLoaderProvider.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 20.06.2023.
//

import Foundation

import CoreML
import Vision

typealias ModelLoader = () throws -> VNCoreMLModel

enum ProcessingType {
    case upscaling
    case lightEnhancing
    
    var method: ProcessingMethod {
        switch self {
        case .upscaling, .lightEnhancing:
            return .imageToImage
        }
    }
}

enum ProcessingMethod {
    case imageToImage
}

extension ProcessingType {
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
    static func loadUpscalingModel() throws -> VNCoreMLModel {
        let configuration = MLModelConfiguration()
        let coreMLModel = try RealesrGAN(configuration: configuration)
        let visionModel = try VNCoreMLModel(for: coreMLModel.model)
                        
        return visionModel
    }
    
    static func loadLightEnhancingModel() throws -> VNCoreMLModel {
        let configuration = MLModelConfiguration()
        let coreMLModel = try Zero_DCE(configuration: configuration)
        let visionModel = try VNCoreMLModel(for: coreMLModel.model)
                        
        return visionModel
    }
}
