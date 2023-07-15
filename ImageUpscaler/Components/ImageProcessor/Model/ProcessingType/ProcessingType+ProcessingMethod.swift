//
//  ProcessingType+ProcessingMethod.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 15.07.2023.
//

import Foundation

/// Enum representing different processing methods.
enum ProcessingMethod {
    case imageToImage
}

extension ProcessingType {
    /// Returns the processing method associated with the processing type.
    var method: ProcessingMethod {
        switch self {
        case .upscaling, .lightEnhancing:
            return .imageToImage
        }
    }

    /// Returns whether the processing type is an image-to-image processing type.
    var isImageToImage: Bool {
        method == .imageToImage
    }
}

extension ProcessingMethod {
    /// String representing localization prefix for processing method.
    private var localizationPrefix: String {
        switch self {
        case .imageToImage:
            return "processing.method.img2img"
        }
    }
    
    /// The title representing the processing method.
    var title: String {
        switch self {
        case .imageToImage:
            return "\(localizationPrefix).title".localized
        }
    }
}
