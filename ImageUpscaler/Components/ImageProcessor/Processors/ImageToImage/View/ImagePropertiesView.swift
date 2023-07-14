//
//  ImagePropertiesView.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 13.07.2023.
//

import SwiftUI

struct ImagePropertiesView: View {
    private typealias InfoRow = (title: String, value: String)
    
    @State var showingInfo = false
    
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
        .background(.thinMaterial)
        .cornerRadius(8)
        .padding()
        .animation(.easeOut, value: showingInfo)
    }
    
    private var infoPlaceholder: some View {
        Label {
            Text("Properties")
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
    
    private var infoValues: [InfoRow] {
        [
            InfoRow(title: "Width", value: "\(Int(image.size.width))"),
            InfoRow(title: "Height", value: "\(Int(image.size.height))"),
            InfoRow(title: "Resolution", value: "\(Int(image.scale * 72))")
        ]
    }
}
