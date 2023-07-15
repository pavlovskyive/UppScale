//
//  VerticalLabelStyle.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 13.07.2023.
//

import SwiftUI

/// A custom label style that displays the label's icon and title vertically.
struct VerticalLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.icon
                .imageScale(.large)
            
            configuration.title
                .font(.caption)
        }
        .contentShape(Rectangle())
    }
}
