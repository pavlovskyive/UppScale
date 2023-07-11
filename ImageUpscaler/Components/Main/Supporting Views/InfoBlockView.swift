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
        VStack(spacing: 8) {
            ZStack {
                Image(systemName: "hexagon.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.gray)
                    .opacity(0.2)
                
                Image(systemName: imageSystemName)
                    .font(.system(size: 24))
                    .bold()
                    .opacity(0.6)
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.title3)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .opacity(0.7)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 48)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.08), radius: 8)
    }
    
    init(imageSystemName: String, title: String, subtitle: String? = nil) {
        self.imageSystemName = imageSystemName
        self.title = title
        self.subtitle = subtitle
    }
}
