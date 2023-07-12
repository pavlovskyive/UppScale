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
        Group {
            if let eventUpdate {
                VStack(alignment: .leading) {
                    HStack(spacing: 4) {
                        if let onCancel {
                            Button {
                                onCancel()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.plain)
                        }
                        
                        if let message = eventUpdate.message {
                            Text(message).minimumScaleFactor(0.8)
                        }
                        
                        if eventUpdate.completionRatio != 1 {
                            ProgressView().progressViewStyle(.circular)
                        }
                    }
                    
                    Spacer()
                    
                    ProgressView(value: eventUpdate.completionRatio)
                }
                .progressViewStyle(.linear)
                .padding(16)
                .frame(maxWidth: 500, maxHeight: 75)
                .background(.thinMaterial)
                .cornerRadius(16)
                .transition(AnyTransition.move(edge: .bottom))
            }
        }
        .padding()
        .animation(.easeOut, value: eventUpdate)
    }
}
