//
//  InfoBlockView.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 17.06.2023.
//

import SwiftUI

struct InfoBlockView: View {
    let imageSystemName: String
    let title: String
    let subtitle: String?
    
    var body: some View {
        VStack(spacing: .xSmall) {
            ZStack {
                Image(systemName: "hexagon.fill")
                    .font(.system(size: .xxxLarge))
                    .foregroundColor(.gray)
                    .opacity(0.2)
                
                Image(systemName: imageSystemName)
                    .font(.system(size: .medium))
                    .bold()
                    .opacity(0.6)
            }
            
            VStack(spacing: .xxxSmall) {
                Text(title)
                    .font(.title3)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .opacity(0.7)
                }
            }
        }
        .padding(.horizontal, .large)
        .padding(.vertical, .xLarge)
        .background(.ultraThinMaterial)
        .cornerRadius(.medium)
        .shadow(color: .black.opacity(0.08), radius: .xSmall)
    }
    
    init(imageSystemName: String, title: String, subtitle: String? = nil) {
        self.imageSystemName = imageSystemName
        self.title = title
        self.subtitle = subtitle
    }
}
