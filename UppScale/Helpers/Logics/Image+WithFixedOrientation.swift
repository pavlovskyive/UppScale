//
//  Image+WithFixedOrientation.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 13.07.2023.
//

import UIKit

extension UIImage {
    /// Returns a new image with fixed orientation if needed.
    var withFixedOrientation: UIImage? {
        switch imageOrientation {
        case .up:
            return self
        default:
            let renderer = UIGraphicsImageRenderer(size: size, format: .init(for: traitCollection))
            
            return renderer.image { _ in
                draw(in: CGRect(origin: .zero, size: size))
            }
        }
    }
}

extension CGImage {
    /// Returns a new CGImage with fixed orientation.
    var withFixedOrientation: CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        let cgContext = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )
        
        guard let cgContext else {
            return nil
        }

        cgContext.translateBy(x: 0, y: CGFloat(height))
        cgContext.scaleBy(x: 1, y: -1)
        
        cgContext.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let cgImage = cgContext.makeImage() else {
            return nil
        }
        
        return cgImage
    }
}
