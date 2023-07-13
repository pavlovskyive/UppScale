//
//  ImagePropertiesView.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 13.07.2023.
//

import SwiftUI

struct ImagePropertiesView: View {
    let image: UIImage

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Width:")
                Spacer()
                Text("\(Int(image.size.width))")
            }
            HStack {
                Text("Height:")
                Spacer()
                Text("\(Int(image.size.height))")
            }
            HStack {
                Text("Resolution:")
                Spacer()
                Text("\(Int(image.scale * 72)) DPI")
            }
        }
        .font(.caption)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: 120)
        .padding()
        .background(.thinMaterial)
        .cornerRadius(8)
        .padding()
    }
}
