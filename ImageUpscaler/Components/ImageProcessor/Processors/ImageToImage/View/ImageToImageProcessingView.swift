//
//  ImageToImageProcessingView.swift
//
//
//  Created by Vsevolod Pavlovskyi on 09.07.2023.
//

import SwiftUI

struct ImageToImageProcessingView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject var viewModel: ImageToImageProcessingViewModel
    @State private var isShowingSettings = false
    @State private var isShowingComparison = false
    
    init(processor: ImageToImageProcessor, uiImage: UIImage) {
        let viewModel = ImageToImageProcessingViewModel(
            processor: processor,
            uiImage: uiImage
        )
        
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            imageView
            
            toolsView
            progressView
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private extension ImageToImageProcessingView {
    @ViewBuilder
    var resetButton: some View {
        if viewModel.processedImage != nil, !viewModel.isBusy {
            Button {
                viewModel.processedImage = nil
            } label: {
                Text("Reset")
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding()
        }
    }
    
    var progressView: some View {
        VStack {
            MaterialProgressView(
                progress: viewModel.processingProgress,
                onCancel: viewModel.cancel
            )
            
            Spacer()
        }
    }
    
    var toolsView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            HStack(alignment: .bottom) {
                resetButton
                
                Spacer()
                
                ImagePropertiesView(image: displayedUIImage)
            }

            HStack(spacing: 0) {
                backButton
                Spacer()
                settingsButton
                Spacer()
                processButton
                Spacer()
                comparisonButton
            }
            .padding([.horizontal])
            .padding(.bottom, 32)
            .background(
                Rectangle()
                    .fill(.thinMaterial)
            )
        }
        .edgesIgnoringSafeArea([.bottom, .horizontal])
    }
    
    var backButton: some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .imageScale(.large)
                .padding()
        }
    }
    
    var settingsButton: some View {
        Button {
            isShowingSettings.toggle()
        } label: {
            Image(systemName: "gear")
                .imageScale(.large)
                .padding()
        }
        .disabled(viewModel.isBusy || viewModel.processedImage != nil)
        .sheet(isPresented: $isShowingSettings) {
            ImageToImageConfigurationView(configuration: $viewModel.configuration)
        }
    }
    
    var processButton: some View {
        Button {
            viewModel.process()
        } label: {
            Image(systemName: "wand.and.rays")
                .imageScale(.large)
                .padding()
        }
        .disabled(viewModel.isBusy || viewModel.processedImage != nil)
    }
    
    var comparisonButton: some View {
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
        .disabled(viewModel.isBusy || viewModel.processedImage == nil)
    }
    
    var imageView: some View {
        ScalableImageView(image: displayedImage)
            .background(backgroundImage)
            .edgesIgnoringSafeArea(.all)
    }
    
    var backgroundImage: some View {
        displayedImage
            .resizable()
            .aspectRatio(contentMode: .fill)
            .overlay(.thinMaterial)
    }
    
    var displayedImage: Image {
        Image(uiImage: displayedUIImage)
    }
    
    var displayedUIImage: UIImage {
        isShowingComparison
            ? viewModel.initialImage
            : viewModel.processedImage ?? viewModel.initialImage
    }
}
