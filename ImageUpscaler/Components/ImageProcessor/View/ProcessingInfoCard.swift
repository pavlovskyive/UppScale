//
//  ProcessingInfoCard.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 17.06.2023.
//

import SwiftUI

struct ProcessingInfoCard: View {
    let processingType: ProcessingType
    
    var body: some View {
        backgroundImage
            .overlay(
                VStack {
                    Text(processingType.title)
                        .bold()
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .offset(y: -8)

                    Spacer()
                    ProcessingInfoCardBody(
                        processingType: processingType
                    )
                    .frame(height: 200)
                    .offset(y: 16)
                }
                .padding(.horizontal)
            )
            .padding(.vertical, 16)
    }
    
    init(processingType: ProcessingType) {
        self.processingType = processingType
    }
}

private extension ProcessingInfoCard {
    var backgroundImage: some View {
        Image(processingType.imageName)
            .resizable()
            .frame(height: 256)
            .scaledToFill()
            .clipped()
            .cornerRadius(16)
        
            .overlay(.background.opacity(0.16))
    }
}

private extension ProcessingType {
    var imageName: String {
        switch self {
        case .upscaling:
            return "info-back-upscaling"
        case .lightEnhancing:
            return "info-back-light-enh"
        }
    }
    
    var outputSize: String {
        switch self {
        case .upscaling:
            return "2048x2048"
        case .lightEnhancing:
            return "512x512"
        }
    }
    
    var usageNote: String {
        switch self {
        case .upscaling:
            return "Best results are achieved with low resolution images."
        case .lightEnhancing:
            return "Best results are achieved via post-processing using upscaling."
        }
    }
    
    var modelName: String {
        switch self {
        case .upscaling:
            return "Real-ESRGAN"
        case .lightEnhancing:
            return "Zero-DCE"
        }
    }
}

private extension ProcessingMethod {
    var title: String {
        switch self {
        case .imageToImage:
            return "img2img"
        }
    }
}

struct ProcessingInfoCardBody: View {
    let processingType: ProcessingType
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(processingType.subtitle)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Model")
                        .font(.caption)
                    Text(processingType.modelName)
                        .minimumScaleFactor(0.8)
                }
                
                Divider()
                
                VStack(alignment: .leading) {
                    Text("Output")
                        .font(.caption)
                    Text(processingType.outputSize)
                        .minimumScaleFactor(0.8)
                }
                
                Divider()
                
                VStack(alignment: .leading) {
                    Text("Type")
                        .font(.caption)
                    Text(processingType.method.title)
                        .minimumScaleFactor(0.8)
                }
                
                Spacer()
            }
            .frame(height: 50)
            
            Text("Hint")
                .font(.caption)
            
            Text(processingType.usageNote)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}
