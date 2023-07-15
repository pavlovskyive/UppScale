//
//  ImageToImageProcessingError.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 14.07.2023.
//

import Foundation

/// Errors that can occur during image-to-image processing.
enum ImageToImageProcessingError: LocalizedError {
    case modelLoadingError
    case invalidData
    case tilingError
    case processingError
    case postprocessingError
    
    private var localizationPrefix: String {
        switch self {
        case .modelLoadingError:
            return "error.modelLoading"
        case .invalidData:
            return "error.invalidData"
        case .tilingError:
            return "error.tiling"
        case .processingError:
            return "error.processing"
        case .postprocessingError:
            return "error.postprocessing"
        }
    }
    
    var errorDescription: String? {
        "\(localizationPrefix).description".localized
    }
    
    var recoverySuggestion: String? {
        "\(localizationPrefix).suggestion".localized
    }
}
