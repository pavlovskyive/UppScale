//
//  MaterialProgressView.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 10.07.2023.
//

import SwiftUI

struct MaterialProgressView: View {
    private var eventUpdate: ProgressEventUpdate?
    private var onCancel: (() -> Void)?
    
    init(
        eventUpdate: ProgressEventUpdate?,
        onCancel: (() -> Void)? = nil
    ) {
        self.eventUpdate = eventUpdate
        self.onCancel = onCancel
    }
    
    var body: some View {
        content
            .padding()
            .animation(.easeOut, value: eventUpdate)
    }
}

private extension MaterialProgressView {
    @ViewBuilder var content: some View {
        if eventUpdate != nil {
            VStack(alignment: .leading) {
                HStack(spacing: 8) {
                    cancelButton
                    
                    message
                    
                    circularProgress
                }
                
                linearProgress
            }
            .padding(16)
            .frame(maxWidth: 500)
            .background(.thinMaterial)
            .cornerRadius(16)
            .transition(AnyTransition.move(edge: .bottom))
        }
    }
    
    @ViewBuilder var cancelButton: some View {
        if let onCancel {
            Button {
                onCancel()
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder var message: some View {
        if let message = eventUpdate?.message {
            Text(message).minimumScaleFactor(0.8)
        }
    }
    
    @ViewBuilder var circularProgress: some View {
        if eventUpdate?.completionRatio != 1 {
            ProgressView().progressViewStyle(.circular).tint(.accentColor)
        }
    }
    
    @ViewBuilder var linearProgress: some View {
        if let value = eventUpdate?.completionRatio {
            ProgressView(value: value)
                .progressViewStyle(.linear)
        }
    }
}
