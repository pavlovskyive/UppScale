//
//  ImageDetailView.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 17.06.2023.
//

import SwiftUI

struct ImageDetailView: View {
    @EnvironmentObject var upscalingService: UpscalingService
    
    private let imageData: Data
    
    @State private var scale = 1.0
    @State private var scalingDisabled = false
    private let minimumScaling = 1.0
    private let maximumScaling = 4.0
    private let scalingStep = 1.0
    
    @State private var globalOffset = CGSize.zero
    @State private var translationOffset = CGSize.zero
    
    @State private var upscaledImage: Image?
    @State private var showingComparison = false
    @State private var imageTileSize = 512
    
    var body: some View {
        ZStack {
            Spacer()
            
            imageView
                .scaleEffect(scale)
                .offset(translationOffset)
            
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            let currentOffset = CGSize(
                                width: gesture.translation.width + globalOffset.width,
                                height: gesture.translation.height + globalOffset.height
                            )

                            withAnimation {
                                translationOffset = currentOffset
                            }
                        }
                        .onEnded { _ in
                            guard scale > 1 else {
                                withAnimation {
                                    translationOffset = globalOffset
                                }
                                
                                return
                            }
                            
                            globalOffset = translationOffset
                        }
                )
            VStack {
                Spacer()
                Text(upscalingService.currentLog)
                HStack {
                    Spacer()
                    tools
                    Spacer()
                }
            }
        }
        .background(backgroundImage)
        
        .materialNavigation()
        .navigationTitle("Image processing")
    }
    
    init(imageData: Data) {
        self.imageData = imageData
    }
}

private extension ImageDetailView {
    var imageView: some View {
        resultingImage?
            .resizable()
            .aspectRatio(contentMode: .fit)
            .transaction { transaction in
                transaction.animation = nil
            }
    }
    
    var resultingImage: Image? {
        if let upscaledImage, !showingComparison {
            return upscaledImage
        } else {
            return initialImage
        }
    }
    
    var initialImage: Image? {
        guard let uiImage = UIImage(data: imageData) else {
            return nil
        }
        
        return Image(uiImage: uiImage)
    }
    
    var backgroundImage: some View {
        initialImage?
            .resizable()
            .scaledToFill()
            .edgesIgnoringSafeArea(.all)
            .overlay(.thinMaterial)
            .transaction { transaction in
                transaction.animation = nil
            }
    }
    
    var tools: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {} label: {
                    Image(systemName: "minus.magnifyingglass")
                        .resizable()
                        .scaledToFit()
                        .frame(height: .medium)
                        .opacity(0.8)
                        .padding()
                }
                .disabled(scale <= minimumScaling)
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.2, maximumDistance: 50)
                        .onEnded { _ in
                            changeImageScaling(to: minimumScaling)
                        }
                )
                .highPriorityGesture(
                    TapGesture()
                        .onEnded { _ in
                            changeImageScaling(to: scale - scalingStep)
                        }
                )
                
                toolDivider
                
                Button {} label: {
                    Image(systemName: "plus.magnifyingglass")
                        .resizable()
                        .scaledToFit()
                        .frame(height: .medium)
                        .opacity(0.8)
                        .padding()
                }
                .disabled(scale >= maximumScaling)
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.2, maximumDistance: 50)
                        .onEnded { _ in
                            changeImageScaling(to: maximumScaling)
                        }
                )
                .highPriorityGesture(
                    TapGesture()
                        .onEnded { _ in
                            changeImageScaling(to: scale + scalingStep)
                        }
                )
            }
            .padding(.horizontal, .xSmall)
            
            .background(.thinMaterial)
            .cornerRadius(.medium)
            .shadow(color: .black.opacity(0.2), radius: .small)
            
            Spacer()
                .frame(maxWidth: .medium)
            
            if upscaledImage == nil {
                Button {
                    Task {
                        let result = await upscalingService.upscaleImage(imageData: imageData)
                        
                        switch result {
                        case .success(let image):
                            upscaledImage = image
                        case .failure(let error):
                            print(error)
                        }
                    }
                } label: {
                    Image(systemName: "wand.and.rays")
                        .resizable()
                        .scaledToFit()
                        .frame(height: .medium)
                        .opacity(0.8)
                        .padding()
                        .overlay(upscalingService.isBusy ? ProgressView() : nil)
                }
                .disabled(upscalingService.isBusy)
                
                .padding(.horizontal, .xSmall)
                .background(.thinMaterial)
                .cornerRadius(.medium)
                .shadow(color: .black.opacity(0.2), radius: .small)
            } else {
                Image(systemName: "arrow.left.arrow.right")
                    .resizable()
                    .scaledToFit()
                    .frame(height: .medium)
                    .opacity(0.8)
                    .padding()
                
                    .padding(.horizontal, .xSmall)
                    .background(.thinMaterial)
                    .cornerRadius(.medium)
                    .shadow(color: .black.opacity(0.2), radius: .small)
                
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                showingComparison = true
                            }
                            .onEnded { _ in
                                showingComparison = false
                            }
                    )
            }
        }
        .buttonStyle(.plain)
        .padding()
    }
    
    var toolDivider: some View {
        Rectangle().fill(.primary.opacity(0.4)).frame(width: 1, height: .large)
    }
    
    func changeImageScaling(to value: Double) {
        guard !scalingDisabled else {
            return
        }
        
        scalingDisabled = true
        
        if value < scale {
            withAnimation {
                translationOffset = .zero
                globalOffset = .zero
            }
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = max(min(value, maximumScaling), minimumScaling)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            scalingDisabled = false
        }
    }
}
