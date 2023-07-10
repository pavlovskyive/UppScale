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
                        Text(message)
                            .animation(.none)
                    }
                    
                    ProgressView(value: eventUpdate.completionRatio)
                }
                .progressViewStyle(.linear)
                .padding(16)
                .background(.thinMaterial)
                .cornerRadius(16)
                .frame(width: 400)
                .transition(AnyTransition.move(edge: .bottom))
            }
        }
        .animation(.easeOut, value: eventUpdate)
    }
}
