//
//  MaterialProgressView.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 10.07.2023.
//

import SwiftUI

struct MaterialProgressView: View {
    private var eventUpdate: ProgressEventUpdate?
    
    init(eventUpdate: ProgressEventUpdate?) {
        self.eventUpdate = eventUpdate
    }
    
    var body: some View {
        Group {
            if let eventUpdate {
                VStack(alignment: .leading) {
                    if let message = eventUpdate.message {
                        Text(message).minimumScaleFactor(0.8)
                    }
                    
                    Spacer()
                    
                    ProgressView(value: eventUpdate.completionRatio)
                }
                .progressViewStyle(.linear)
                .padding(16)
                .frame(maxWidth: 500, maxHeight: 100)
                .background(.thinMaterial)
                .cornerRadius(16)
                .transition(AnyTransition.move(edge: .bottom))
            }
        }
        .padding()
        .animation(.easeOut, value: eventUpdate)
    }
}
