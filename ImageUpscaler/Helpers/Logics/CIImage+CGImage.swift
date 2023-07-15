//
//  CIImage+CGImage.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 13.07.2023.
//

import CoreImage

extension CIImage {
    /// Converts the CIImage to a CGImage using the specified CIContext.
    ///
    /// - Parameter context: The CIContext to use for creating the CGImage. The default value is a new CIContext.
    /// - Returns: The converted CGImage or nil if the conversion fails.
    func cgImage(context: CIContext = CIContext()) -> CGImage? {
        context.createCGImage(self, from: extent)
    }
}
