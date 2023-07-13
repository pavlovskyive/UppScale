//
//  ImageToImageConfigurationView.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 12.07.2023.
//

import SwiftUI

struct ImageToImageConfigurationView: View {
    @Binding var configuration: ImageToImageConfiguration
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Tile Size")) {
                    Picker(
                        selection: $configuration.tileSize,
                        label: Text("Tile Size")
                    ) {
                        ForEach(configuration.tileSizes, id: \.self) { size in
                            Text("\(size)")
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Overlap")) {
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
                        Text("Overlap")
                    }
                }
            }
            .navigationTitle("Processing Parameters")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

private extension Double {
    var percentValueDescription: String {
        "\(Int(self * 100))%"
    }
}
