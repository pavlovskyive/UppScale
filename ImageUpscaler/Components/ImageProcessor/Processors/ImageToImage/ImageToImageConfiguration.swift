//
//  ImageToImageConfiguration.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 13.07.2023.
//

import Foundation

struct ImageToImageConfiguration {
    let tileSizes = [512, 768, 1024, 2048]
    let overlapRange = 0.1...0.5
    
    var tileSize = 1024
    var overlap = 0.2
}
