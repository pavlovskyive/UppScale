//
//  ToolsView.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 23.06.2023.
//

import SwiftUI

//extension ImageProcessingView {
//    var toolsView: some View {
//        HStack(alignment: .center) {
//            cancelButton
//            Spacer()
//            upscaleButton
//            toolDivider
//            lightEnhanceButton
//            toolDivider
//            compareButton
//            Spacer()
//            saveButton
//        }
//        .padding(.horizontal, .small)
//        .padding(.vertical, .medium)
//        .background(
//            Rectangle()
//                .fill(.thinMaterial)
//                .cornerRadius(.medium)
//        )
//        .padding([.horizontal, .top])
//        .edgesIgnoringSafeArea(.bottom)
//        .labelStyle(VerticalLabelStyle())
//    }
//}
//
//private extension ImageProcessingView {
//    var cancelButton: some View {
//        Label("Cancel", systemImage: "chevron.backward")
//            .onTapGesture {
//                presentationMode.wrappedValue.dismiss()
//            }
//    }
//    
//    var upscaleButton: some View {
//        Label("Upscale", systemImage: "wand.and.rays")
//            .onTapGesture {
//                Task(priority: .high) {
//                    do {
//                        guard let uiImage = initialUIImage else {
//                            throw ImageProcessingError.invalidParametersData // TODO: change
//                        }
//
//                        let processedUIImage = try await imageProcessingManager.processImage(
//                            type: UpscalingProcessor.self,
//                            parameters: UpscalingProcessor.Parameters(uiImage: uiImage)
//                        )
//                        
//                        self.processedUIImage = processedUIImage
//                    } catch {
//                        self.error = error
//                    }
//                }
//            }
//            .disabled(imageProcessingManager.isBusy)
//            .opacity(imageProcessingManager.isBusy || processedUIImage != nil ? 0.3 : 1)
//    }
//    
//    var lightEnhanceButton: some View {
//        Label("Enhance Light", systemImage: "flashlight.on.fill")
//            .onTapGesture {
//                Task(priority: .high) {
//                    do {
//                        guard let uiImage = initialUIImage else {
//                            throw ImageProcessingError.invalidParametersData // TODO: change
//                        }
//
//                        let processedUIImage = try await imageProcessingManager.processImage(
//                            type: LightEnhancementProcessor.self,
//                            parameters: LightEnhancementProcessor.Parameters(uiImage: uiImage)
//                        )
//                        
//                        self.processedUIImage = processedUIImage
//                    } catch {
//                        self.error = error
//                    }
//                }
//            }
//            .disabled(imageProcessingManager.isBusy)
//            .opacity(imageProcessingManager.isBusy || processedUIImage != nil ? 0.3 : 1)
//    }
//    
//    var compareButton: some View {
//        Label("Compare", systemImage: "eye")
//            .gesture(
//                DragGesture(minimumDistance: 0)
//                    .onChanged { _ in
//                        showingComparison = true
//                    }
//                    .onEnded { _ in
//                        showingComparison = false
//                    }
//            )
//            .disabled(processedUIImage == nil)
//            .opacity(processedUIImage == nil ? 0.3 : 1)
//    }
//    
//    var saveButton: some View {
//        Label("Save", systemImage: "square.and.arrow.down")
//            .onTapGesture {
//                guard let processedUIImage else {
//                    return // TODO: handle
//                }
//                
//                UIImageWriteToSavedPhotosAlbum(processedUIImage, nil, nil, nil)
//                
//                // TODO: alert and dismiss
//            }
//            .disabled(processedUIImage == nil)
//            .opacity(processedUIImage == nil ? 0.3 : 1)
//    }
//    
//    var toolDivider: some View {
//        Rectangle()
//            .fill(.primary.opacity(0.2))
//            .frame(width: 1, height: .medium)
//    }
//}
//
//struct VerticalLabelStyle: LabelStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        VStack(spacing: .xxSmall) {
//            configuration.icon
//                .frame(height: .medium, alignment: .center)
//
//            configuration.title
//                .font(.caption)
//                .opacity(0.7)
//        }
//    }
//}
