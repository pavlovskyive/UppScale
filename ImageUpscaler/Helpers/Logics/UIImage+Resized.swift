//
//  UIImage+Resized.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 13.07.2023.
//

import UIKit

extension UIImage {
    /// Resizes the image to the specified size.
    ///
    /// - Parameter size: The desired size of the image.
    /// - Returns: The resized image, or nil if resizing fails.
    func resized(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(
            size: size,
            format: .init(for: traitCollection)
        )
        
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
