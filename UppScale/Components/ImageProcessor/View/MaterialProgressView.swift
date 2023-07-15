//
//  MaterialProgressView.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 10.07.2023.
//

import SwiftUI

/// A view that displays a material-style progress indicator.
struct MaterialProgressView: View {
    private var progress: ProcessingProgress?
    private var onCancel: (() -> Void)?
    
    /// Initializes a `MaterialProgressView` with the given progress and cancel action.
    /// - Parameters:
    ///   - progress: The progress to display.
    ///   - onCancel: The action to perform when the cancel button is tapped.
    init(
        progress: ProcessingProgress?,
        onCancel: (() -> Void)? = nil
    ) {
        self.progress = progress
        self.onCancel = onCancel
    }
    
    var body: some View {
        content
            .padding()
            .animation(.easeOut, value: progress)
    }
}

private extension MaterialProgressView {
    @ViewBuilder var content: some View {
        if progress != nil {
            VStack(alignment: .leading) {
                HStack(spacing: 8) {
                    cancelButton
                    
                    message
                    
                    circularProgress
                    
                    Spacer()
                }
                
                linearProgress
            }
            .padding(16)
            .frame(maxWidth: 500)
            .background(.thinMaterial)
            .cornerRadius(16)
            .transition(.push(from: .top))
        }
    }
    
    @ViewBuilder var cancelButton: some View {
        if let onCancel, progress?.completionRatio != 1 {
            Button {
                onCancel()
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder var message: some View {
        if let message = progress?.message {
            Text(message)
                .minimumScaleFactor(0.8)
                .animation(.none, value: message)
        }
    }
    
    @ViewBuilder var circularProgress: some View {
        if progress?.completionRatio != 1 {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.accentColor)
        }
    }
    
    @ViewBuilder var linearProgress: some View {
        if let value = progress?.completionRatio {
            ProgressView(value: value)
                .progressViewStyle(.linear)
        }
    }
}
