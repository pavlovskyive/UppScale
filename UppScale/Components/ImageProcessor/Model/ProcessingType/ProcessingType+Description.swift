//
//  ProcessingType+Description.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 15.07.2023.
//

import Foundation

extension ProcessingType {
    /// String representing localization prefix for the processing type.
    private var localizationPrefix: String {
        switch self {
        case .upscaling:
            return "processing.superResolution"
        case .lightEnhancing:
            return "processing.lightEnhancement"
        }
    }
    
    /// The title representing the processing type.
    var title: String {
        "\(localizationPrefix).title".localized
    }
    
    /// The subtitle title representing the processing type.
    var subtitle: String {
        "\(localizationPrefix).subtitle".localized
    }
    
    /// The action title representing the processing type.
    var actionTitle: String {
        "\(localizationPrefix).actionTitle".localized
    }
    
    /// The model name representing the processing type.
    var modelName: String {
        "\(localizationPrefix).modelTitle".localized
    }
    
    /// The output size description representing the processing type.
    var outputSize: String {
        switch self {
        case .upscaling:
            return "2048x2048"
        case .lightEnhancing:
            return "512x512"
        }
    }
    
    /// The usage note representing additional information or instructions for the processing type.
    var usageNote: String {
        "\(localizationPrefix).usageNote".localized
    }
}
