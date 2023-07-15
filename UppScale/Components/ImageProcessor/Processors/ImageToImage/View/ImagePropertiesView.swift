//
//  ImagePropertiesView.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 13.07.2023.
//

import SwiftUI

/// A view that displays the properties of an image and toggles between placeholder and detailed information.
struct ImagePropertiesView: View {
    private typealias InfoRow = (title: String, value: String)
    
    @State var showingInfo = false
    
    /// The image whose properties will be displayed.
    let image: UIImage

    var body: some View {
        Button {
            showingInfo.toggle()
        } label: {
            if showingInfo {
                infoRows
            } else {
                infoPlaceholder
            }
        }
        .padding()
        .background(.thickMaterial)
        .cornerRadius(8)
        .padding()
        .animation(.easeOut, value: showingInfo)
    }
    
    // MARK: - Views
    
    private var infoPlaceholder: some View {
        Label {
            Text("button.properties")
        } icon: {
            Image(systemName: "info.circle")
        }
        .transition(.push(from: .top))
    }
    
    private var infoRows: some View {
        VStack {
            ForEach(infoValues, id: \.title) { row in
                HStack {
                    Text(row.title)
                    Spacer()
                    Text(row.value)
                }
            }
        }
        .font(.caption)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: 120)
        .transition(.push(from: .top))
    }
    
    // MARK: - Helpers
    
    private var infoValues: [InfoRow] {
        [
            InfoRow(title: "label.width".localized, value: "\(Int(image.size.width))"),
            InfoRow(title: "label.height".localized, value: "\(Int(image.size.height))"),
            InfoRow(title: "label.resolution".localized, value: "\(Int(image.scale * 72))")
        ]
    }
}
