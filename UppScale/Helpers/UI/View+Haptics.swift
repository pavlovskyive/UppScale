//
//  View+Haptics.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 13.07.2023.
//

import SwiftUI

extension View {
    /// Triggers haptic feedback with the specified style.
    ///
    /// - Parameter style: The feedback style of the haptic feedback.
    func haptics(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        // Create a UIImpactFeedbackGenerator with the specified style.
        let feedbackGenerator = UIImpactFeedbackGenerator(style: style)
        
        // Trigger the haptic feedback.
        feedbackGenerator.impactOccurred()
    }
}
