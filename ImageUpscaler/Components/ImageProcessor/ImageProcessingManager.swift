//
//  ImageProcessingManager.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 20.06.2023.
//

import SwiftUI
import Vision
import CoreML

class ImageProcessingManager: ObservableObject {
    private var processorsCache: [String: any ImageProcessing] = [:]
    
    @Published var isBusy = false

    func processImage<P: ImageProcessing>(
        type: P.Type, parameters: P.Parameters
    ) async throws -> UIImage {
        DispatchQueue.main.async { [weak self] in
            self?.isBusy = true
        }
        
        defer {
            DispatchQueue.main.async { [weak self] in
                self?.isBusy = false
            }
        }
        
        let processor = try getProcessor(type: P.self)
        return try await processor.processImage(parameters: parameters)
    }
    
    private func getProcessor<P: ImageProcessing>(type: P.Type) throws -> P {
        let key = String(describing: type)
        
        if let processor = processorsCache[key] as? P {
            return processor
        }
        
        let processor = try P(manager: self)
        processorsCache[key] = processor
        
        return processor
    }
}

enum ImageProcessingError: LocalizedError {
    case modelLoadingError
    case invalidParametersData
    case processingError
}

extension ImageProcessingError {
    var errorDescription: String? {
        switch self {
        case .modelLoadingError:
            return "Model could not be loaded"
        case .invalidParametersData:
            return "Parameters passed to the model are not correct"
        case .processingError:
            return "Image processing error"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .modelLoadingError:
            return "Try again or restart the application"
        case .invalidParametersData:
            return "Try selecting different image or restart the application"
        case .processingError:
            return "Check for available memory and/or turn off battery saving mode"
        }
    }
}
