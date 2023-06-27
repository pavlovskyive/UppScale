//
//  MLImageProcessable.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 20.06.2023.
//

import SwiftUI
import Vision
import CoreML

protocol MLImageProcessable {
    func loadModel() async throws
    func processImage(_ uiImage: UIImage) async throws -> Image
}

enum MLImageProcessingError: Error {
    case modelLoadingError
    case invalidImageData
    case imageProcessingError
    case imageConversionError
}
