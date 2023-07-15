//
//  ProcessingInfoCard.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 17.06.2023.
//

import SwiftUI

// MARK: - ProcessingInfoCard

/// A card view that displays information about a processing type.
struct ProcessingInfoCard: View {
    let processingType: ProcessingType
    
    var body: some View {
        backgroundImage
            .overlay(
                VStack {
                    Text(processingType.title)
                        .bold()
                        .padding()
                        .background(.thickMaterial)
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
    
    /// Initializes a `ProcessingInfoCard` with the given processing type.
    /// - Parameter processingType: The processing type to display information about.
    init(processingType: ProcessingType) {
        self.processingType = processingType
    }
    
    private var backgroundImage: some View {
        Image(processingType.imageName)
            .resizable()
            .frame(height: 256)
            .scaledToFill()
            .clipped()
            .cornerRadius(16)
            .overlay(Color.black.opacity(0.16))
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
}

// MARK: - ProcessingInfoCardBody

/// The body view for displaying information about a processing type.
struct ProcessingInfoCardBody: View {
    let processingType: ProcessingType
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(processingType.title)
            
            HStack {
                infoItem(
                    title: "label.model".localized,
                    subtitle: processingType.modelName
                )
                
                Divider()
                
                infoItem(
                    title: "label.output".localized,
                    subtitle: processingType.outputSize
                )
                
                Divider()
                
                infoItem(
                    title: "label.type".localized,
                    subtitle: processingType.method.title
                )
                
                Spacer()
            }
            .frame(height: 50)
            
            infoItem(
                title: "label.hint".localized,
                subtitle: processingType.usageNote
            )
            
            Spacer()
        }
        .padding()
        .background(.thickMaterial)
        .cornerRadius(16)
    }

    private func infoItem(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
            Text(subtitle)
                .minimumScaleFactor(0.8)
        }
    }
}
