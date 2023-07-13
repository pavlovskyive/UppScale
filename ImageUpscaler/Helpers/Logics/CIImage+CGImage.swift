//
//  CIImage+CGImage.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 13.07.2023.
//

import CoreImage

extension CIImage {
    func cgImage(context: CIContext = CIContext()) -> CGImage? {
        context.createCGImage(self, from: extent)
    }
}
