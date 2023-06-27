//
//  TestProcessor.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 23.06.2023.
//

import SwiftUI

final class TestProcessor: ImageProcessing {
    struct Parameters {
        let data: Data
        let rect: CGRect?
    }
    
    func processImage(parameters: Parameters) async throws -> UIImage {
        guard let uiImage = UIImage(data: parameters.data) else {
            throw ImageProcessingError.processingError
        }
        
        return uiImage
    }
}
