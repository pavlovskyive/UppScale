//
//  ImageToImageSettingsView.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 12.07.2023.
//

import SwiftUI

struct ImageToImageSettingsView: View {
    @ObservedObject var viewModel: ImageToImageProcessingViewModel
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Tile Size")) {
                    Picker(
                        selection: $viewModel.tileSize,
                        label: Text("Tile Size")
                    ) {
                        ForEach(viewModel.tileSizes, id: \.self) { size in
                            Text("\(size)")
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Overlap")) {
                    Slider(
                        value: $viewModel.overlap,
                        in: 0.1...0.5,
                        step: 0.1,
                        minimumValueLabel: Text("10%"),
                        maximumValueLabel: Text("50%")
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
