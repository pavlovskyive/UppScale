//
//  ImageProcessingView.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 17.06.2023.
//

import SwiftUI

struct ImageProcessingView: View {
    @EnvironmentObject var imageProcessingManager: ImageProcessingManager
    @Environment(\.presentationMode) var presentationMode
    
    let initialImageData: Data
    
    @State var processedUIImage: UIImage?
    @State var showingComparison = false
    
    @State var error: Error?
    
    var body: some View {
        if let resultingImage {
            ScalableImageView(image: resultingImage)
                .edgesIgnoringSafeArea(.all)
                .background(backgroundImage)
                .overlay {
                    VStack {
                        Spacer()
                        toolsView
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
                .errorAlert(error: $error)
        }
    }
    
    init(imageData: Data) {
        self.initialImageData = imageData
    }
}

private extension ImageProcessingView {
    var imageView: some View {
        resultingImage?
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
    
    var resultingImage: Image? {
        if let processedImage, !showingComparison {
            return processedImage
        } else {
            return initialImage
        }
    }
    
    var processedImage: Image? {
        guard let uiImage = processedUIImage else {
            return nil
        }
        
        return Image(uiImage: uiImage)
    }
    
    var initialImage: Image? {
        guard let uiImage = UIImage(data: initialImageData) else {
            return nil
        }
        
        return Image(uiImage: uiImage)
    }
    
    var backgroundImage: some View {
        resultingImage?
            .resizable()
            .scaledToFill()
            .edgesIgnoringSafeArea(.all)
            .overlay(.thinMaterial)
    }
}

extension View {
    func errorAlert(error: Binding<Error?>, buttonTitle: String = "OK") -> some View {
        let localizedAlertError = LocalizedAlertError(error: error.wrappedValue)
        return alert(isPresented: .constant(localizedAlertError != nil), error: localizedAlertError) { _ in
            Button(buttonTitle) {
                error.wrappedValue = nil
            }
        } message: { error in
            Text(error.recoverySuggestion ?? "")
        }
    }
}

struct LocalizedAlertError: LocalizedError {
    let underlyingError: LocalizedError
    var errorDescription: String? {
        underlyingError.errorDescription
    }
    var recoverySuggestion: String? {
        underlyingError.recoverySuggestion
    }

    init?(error: Error?) {
        guard let localizedError = error as? LocalizedError else { return nil }
        underlyingError = localizedError
    }
}
