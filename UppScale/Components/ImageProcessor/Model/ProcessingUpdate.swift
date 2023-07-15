//
//  ProcessingUpdate.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 09.07.2023.
//

import SwiftUI

/// Enum representing different types of processing updates.
enum ProcessingUpdate: Equatable {
    /// Represents a processing progress update.
    case progress(ProcessingProgress)
    /// Represents an image update.
    case image(UIImage)
}

/// Struct representing the progress of a processing task.
struct ProcessingProgress: Equatable {
    /// Typealias for the completion ratio value.
    typealias CompletionRatio = Double

    /// Optional message associated with the progress.
    let message: String?
    /// Optional completion ratio indicating the progress.
    let completionRatio: CompletionRatio?

    /// Initializes the progress with an optional message and completion ratio.
    init(message: String? = nil, completionRatio: Double? = nil) {
        self.message = message
        self.completionRatio = completionRatio
    }
}
