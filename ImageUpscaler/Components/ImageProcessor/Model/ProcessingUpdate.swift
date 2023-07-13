//
//  ProcessingUpdate.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 09.07.2023.
//

import SwiftUI

enum ProcessingUpdate: Equatable {
    case progress(ProcessingProgress)
    case image(UIImage)
}

struct ProcessingProgress: Equatable {
    typealias CompletionRatio = Double

    let message: String?
    let completionRatio: CompletionRatio?

    init(message: String? = nil, completionRatio: Double? = nil) {
        self.message = message
        self.completionRatio = completionRatio
    }
}
