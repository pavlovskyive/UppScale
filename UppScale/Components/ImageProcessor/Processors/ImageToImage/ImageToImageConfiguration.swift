//
//  ImageToImageConfiguration.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 13.07.2023.
//

import Foundation

/// Represents the configuration settings for image-to-image processing.
struct ImageToImageConfiguration {
    /// The available tile sizes for processing.
    let tileSizes = [512, 768, 1024, 2048]
    
    /// The range of overlap values.
    let overlapRange = 0.1...0.5
    
    /// The selected tile size for processing.
    var tileSize = 1024
    
    /// The selected overlap value for processing.
    var overlap = 0.2
}
