//
//  CoreGraphics+Arithmetics.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 13.07.2023.
//

import CoreGraphics

extension CGSize {
    static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(
            width: lhs.width + rhs.width,
            height: lhs.height + rhs.height
        )
    }
    
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        lhs.applying(CGAffineTransform(scaleX: rhs, y: rhs))
    }
}

extension CGRect {
    static func * (lhs: CGRect, rhs: CGFloat) -> CGRect {
        lhs.applying(CGAffineTransform(scaleX: rhs, y: rhs))
    }
}
