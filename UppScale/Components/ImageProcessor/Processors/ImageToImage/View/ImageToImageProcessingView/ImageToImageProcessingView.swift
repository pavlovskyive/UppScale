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

    // MARK: - State Variables
    
    @State private var isShowingSettings = false
    @State private var isShowingComparison = false
    @State private var isShowingNextOptions = false
    @State private var isShowingProcessingOptions = false
    @State private var isShowingShareSheet = false
    @State private var isShowingCompletionAlert = false
    
    // MARK: - Initialization
    
    init(processingType: ProcessingType, uiImage: UIImage) {
        let viewModel = ImageToImageProcessingViewModel(
            processingType: processingType,
            initialImage: uiImage
        )

        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - View Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            imageView
            
            toolsView
            progressView
        }
        .toolbar(.hidden, for: .navigationBar)
        .errorAlert(error: $viewModel.error)
    }
}

private extension ImageToImageProcessingView {
    
    // MARK: - Subviews
    
    var resetButton: some View {
        Button {
            viewModel.reset()
        } label: {
            Label("button.reset", systemImage: "arrow.counterclockwise")
                .padding()
                .background(.thickMaterial)
                .cornerRadius(8)
        }
        .padding()
        .disabled(viewModel.state != .finished)
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
                    .fill(.thickMaterial)
                    .edgesIgnoringSafeArea(.all)
            )
        }
    }
    
    // MARK: - Buttons
    
    var backButton: some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Label("button.back", systemImage: "chevron.left")
        }
    }
    
    var settingsButton: some View {
        Button {
            isShowingSettings.toggle()
        } label: {
            Label("button.settings", systemImage: "gear")
        }
        .disabled(viewModel.state != .idle)
        .sheet(isPresented: $isShowingSettings) {
            ImageToImageConfigurationView(configuration: $viewModel.configuration)
        }
    }
    
    var processButton: some View {
        Button {
            viewModel.process()
        } label: {
            Label(viewModel.processingType.actionTitle, systemImage: "wand.and.stars")
        }
        .disabled(viewModel.state != .idle)
    }
    
    var comparisonButton: some View {
        Button {
            isShowingComparison.toggle()
        } label: {
            let imageName = isShowingComparison
                ? "square.filled.and.line.vertical.and.square"
                : "square.and.line.vertical.and.square.filled"

            Label("button.compare", systemImage: imageName)
        }
        .disabled(viewModel.state != .finished)
    }
    
    var nextButton: some View {
        Button {
            isShowingNextOptions.toggle()
        } label: {
            Label("button.next", systemImage: "square.and.arrow.up")
        }
        .disabled(viewModel.state != .finished)
        .confirmationDialog(
            "dialogue.question.continueWithImage",
            isPresented: $isShowingNextOptions
        ) {
            Button {
                isShowingProcessingOptions.toggle()
            } label: {
                Label("button.process", systemImage: "wand.and.stars")
            }
            
            Button {
                isShowingShareSheet.toggle()
            } label: {
                Label("button.share", systemImage: "square.and.arrow.down")
            }
            
            Button("button.cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "dialogue.question.processingMethod",
            isPresented: $isShowingProcessingOptions
        ) {
            let processingOptions = ProcessingType.allCases
                .filter {
                    $0.isImageToImage
                }
                .filter {
                    viewModel.processingType != $0
                }
            
            ForEach(processingOptions, id: \.self) { processingType in
                Button {
                    viewModel.setupNewProcessingType(processingType)
                } label: {
                    Text(processingType.title)
                }
            }
            
            Button("button.cancel", role: .cancel) {}
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let image = viewModel.processedImage {
                let item = ItemDetailSource(
                    name: "label.processedImage".localized,
                    image: image
                )

                ActivityViewController(
                    activityItems: [item],
                    completion: { _, completed, _, error in
                        if let error {
                            viewModel.error = error
                            
                            return
                        }
                        
                        if completed {
                            isShowingCompletionAlert = true
                        }
                    }
                )
            }
        }
        .alert(isPresented: $isShowingCompletionAlert) {
            Alert(
                title: Text("label.completed"),
                message: Text("label.actionCompleted"),
                dismissButton: .default(Text("button.ok"))
            )
        }
    }
    
    // MARK: - Image View
    
    var imageView: some View {
        ScalableImageView(image: displayedImage)
            .background(backgroundImage)
            .edgesIgnoringSafeArea([.top, .horizontal])
    }
    
    var backgroundImage: some View {
        displayedImage
            .resizable()
            .aspectRatio(contentMode: .fill)
            .overlay(.ultraThinMaterial)
    }
    
    // MARK: - Helper Properties
    
    var displayedImage: Image {
        Image(uiImage: displayedUIImage)
    }
    
    var displayedUIImage: UIImage {
        isShowingComparison
            ? viewModel.initialImage
            : viewModel.processedImage ?? viewModel.initialImage
    }
}
