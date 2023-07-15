//
//  CoreGraphics+Arithmetics.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 13.07.2023.
//

import CoreGraphics

extension CGSize {
    /// Adds two CGSize values together.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side CGSize value.
    ///   - rhs: The right-hand side CGSize value.
    /// - Returns: The sum of the two CGSize values.
    static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(
            width: lhs.width + rhs.width,
            height: lhs.height + rhs.height
        )
    }
    
    /// Multiplies a CGSize value by a scalar value.
    ///
    /// - Parameters:
    ///   - lhs: The CGSize value.
    ///   - rhs: The scalar value.
    /// - Returns: The CGSize value multiplied by the scalar.
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        lhs.applying(CGAffineTransform(scaleX: rhs, y: rhs))
    }
}

extension CGRect {
    /// Multiplies a CGRect value by a scalar value.
    ///
    /// - Parameters:
    ///   - lhs: The CGRect value.
    ///   - rhs: The scalar value.
    /// - Returns: The CGRect value multiplied by the scalar.
    static func * (lhs: CGRect, rhs: CGFloat) -> CGRect {
        lhs.applying(CGAffineTransform(scaleX: rhs, y: rhs))
    }
}
