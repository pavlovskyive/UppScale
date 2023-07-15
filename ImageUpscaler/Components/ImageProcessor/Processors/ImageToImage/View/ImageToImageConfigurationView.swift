//
//  ImageToImageConfigurationView.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 12.07.2023.
//

import SwiftUI

/// A view for configuring image-to-image processing parameters.
struct ImageToImageConfigurationView: View {
    /// The binding to the image-to-image configuration.
    @Binding var configuration: ImageToImageConfiguration
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("label.tileSize")) {
                    tileSizeItem
                }
                
                Section(header: Text("label.overlap")) {
                    overlapItem
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("label.processingParameters.title")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

private extension ImageToImageConfigurationView {
    /// The picker view for selecting the tile size.
    var tileSizePicker: some View {
        Picker(
            selection: $configuration.tileSize,
            label: Text("label.tileSize")
        ) {
            ForEach(configuration.tileSizes, id: \.self) { size in
                Text("\(size)")
            }
        }
        .pickerStyle(.segmented)
    }
    
    /// The description for the tile size parameter.
    var tileSizeItem: some View {
        VStack(alignment: .leading) {
            tileSizePicker
                .padding(.bottom, 4)

            Text("label.processingParameters.tileSize.subtitle")
                .font(.headline)
            Text("label.processingParameters.tileSize.note")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    /// The slider view for adjusting the overlap value.
    var overlapSlider: some View {
        Slider(
            value: $configuration.overlap,
            in: configuration.overlapRange,
            step: 0.1,
            minimumValueLabel: Text(
                configuration.overlapRange.lowerBound.percentValueDescription
            ),
            maximumValueLabel: Text(
                configuration.overlapRange.upperBound.percentValueDescription
            )
        ) {
            Text("label.overlap")
        }
    }
    
    /// The description for the overlap parameter.
    var overlapItem: some View {
        VStack(alignment: .leading) {
            overlapSlider

            Text("label.processingParameters.overlap.subtitle")
                .font(.headline)
            Text("label.processingParameters.overlap.note")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private extension Double {
    /// Returns a percent value description for the double.
    var percentValueDescription: String {
        "\(Int(self * 100))%"
    }
}
