//
//  UIImage+Resized.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 13.07.2023.
//

import UIKit

extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size, format: .init(for: traitCollection))

        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
