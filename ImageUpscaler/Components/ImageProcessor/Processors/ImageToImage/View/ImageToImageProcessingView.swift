//
//  ImageToImageProcessingView.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 09.07.2023.
//

import SwiftUI
import Combine

struct ImageToImageProcessingView: View {
    @Environment(\.presentationMode) var presentationMode

    @StateObject var viewModel: ImageToImageProcessingViewModel
    @State private var isShowingComparison = false
    
    private let tileSizes = [512, 768, 1024, 2048]

    init(
        processor: ImageToImageProcessor,
        postProcessor: ImageToImageProcessor? = nil,
        uiImage: UIImage
    ) {
        let viewModel = ImageToImageProcessingViewModel(
            processor: processor,
            postProcessor: postProcessor,
            uiImage: uiImage
        )

        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        imageView
            .overlay {
                VStack(spacing: 0) {
                    Spacer()
                    MaterialProgressView(eventUpdate: viewModel.progressUpdate)
                    toolsView
                }
                .edgesIgnoringSafeArea([.bottom, .horizontal])
            }
            .toolbar(.hidden, for: .navigationBar)
    }
}

private extension ImageToImageProcessingView {
    var toolsView: some View {
        HStack(spacing: 0) {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .imageScale(.large)
                    .padding()
            }
            
            Spacer()
            
            HStack(spacing: 0) {
                Text("Tile size:")
                    .font(.caption)
                
                Picker("Tile size:", selection: $viewModel.tileSize) {
                    ForEach(tileSizes, id: \.self) {
                        Text("\($0)")
                    }
                }
                .pickerStyle(.menu)
            }
            .padding()
            
            Spacer()
            
            Button {
                viewModel.process()
            } label: {
                Image(systemName: "wand.and.rays")
                    .imageScale(.large)
                    .padding()
            }
            .disabled(viewModel.isBusy || viewModel.processedImage != nil)
            
            Spacer()
            
            Button {
                isShowingComparison.toggle()
            } label: {
                let imageName = isShowingComparison
                    ? "square.filled.and.line.vertical.and.square"
                    : "square.and.line.vertical.and.square.filled"

                Image(systemName: imageName)
                    .imageScale(.large)
                    .padding()
            }
            .disabled(viewModel.processedImage == nil)
    
            Spacer()
        }
        .padding([.horizontal])
        .padding(.bottom, 32)
        .background(
            Rectangle()
                .fill(.thinMaterial)
        )
    }
    
    var imageView: some View {
        ScalableImageView(image: resultingImage)
            .edgesIgnoringSafeArea(.all)
            .background(backgroundImage)
    }
    
    var backgroundImage: some View {
        resultingImage
            .resizable()
            .aspectRatio(contentMode: .fill)
            .overlay(.thinMaterial)
    }
    
    var resultingImage: Image {
        if let processedImage, !isShowingComparison {
            return processedImage
        } else {
            return initialImage
        }
    }
    
    var processedImage: Image? {
        guard let uiImage = viewModel.processedImage else {
            return nil
        }
        
        return Image(uiImage: uiImage)
    }

    var initialImage: Image {
        Image(uiImage: viewModel.initialImage)
    }
}
