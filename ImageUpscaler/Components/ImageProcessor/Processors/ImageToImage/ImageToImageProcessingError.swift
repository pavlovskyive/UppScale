//
//  ImageToImageProcessingError.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 14.07.2023.
//

import Foundation

enum ImageToImageProcessingError: LocalizedError {
    case modelLoadingError
    case incorrectImageData
    case tilingError
    case visionRequestError
    case imagePostprocessingError
    
    var errorDescription: String? {
        switch self {
        case .modelLoadingError:
            return "Model loading error"
        case .incorrectImageData:
            return "Incorrect image data"
        case .tilingError:
            return "Tiling error"
        case .visionRequestError:
            return "Vision request error"
        case .imagePostprocessingError:
            return "Image postprocessing error"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .modelLoadingError:
            return "Try to restart the application or try again"
        case .incorrectImageData:
            return "Try to reload the image or choose another one"
        case .tilingError:
            return "Try to reload the image"
        case .visionRequestError:
            return "Try to restart the application or try again"
        case .imagePostprocessingError:
            return "Try again or choose another image"
        }
    }
}
