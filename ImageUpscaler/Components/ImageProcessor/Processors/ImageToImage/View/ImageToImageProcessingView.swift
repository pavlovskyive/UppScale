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
    var resetButton: some View {
        Button {
            viewModel.processedImage = nil
        } label: {
            Label("Reset", systemImage: "arrow.counterclockwise")
                .padding()
                .background(.thinMaterial)
                .cornerRadius(8)
        }
        .padding()
        .disabled(viewModel.isBusy || viewModel.processedImage == nil)
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
                Spacer()
                nextButton
            }
            .labelStyle(VerticalLabelStyle())
            .padding()
            .background(
                Rectangle()
                    .fill(.thinMaterial)
                    .edgesIgnoringSafeArea(.all)
            )
        }
    }
    
    var backButton: some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Label("Back", systemImage: "chevron.left")
        }
    }
    
    var settingsButton: some View {
        Button {
            isShowingSettings.toggle()
        } label: {
            Label("Settings", systemImage: "gear")
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
            Label("Process", systemImage: "wand.and.stars")
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

            Label("Compare", systemImage: imageName)
        }
        .disabled(viewModel.isBusy || viewModel.processedImage == nil)
    }
    
    var nextButton: some View {
        Button {
            // save
        } label: {
            Label("Next", systemImage: "square.and.arrow.up")
        }
        .disabled(viewModel.isBusy || viewModel.processedImage == nil)
    }
    
    var imageView: some View {
        ScalableImageView(image: displayedImage)
            .background(backgroundImage)
            .edgesIgnoringSafeArea([.top, .horizontal])
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
