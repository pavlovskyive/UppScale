//
//  ImagePickerView.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 16.06.2023.
//

import SwiftUI
import PhotosUI

struct ImagePickerView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    
    @State private var error: Error?
    
    var body: some View {
        VStack {
            Spacer()
            
            image
            
            Spacer()
            
            operations
        }
        .errorAlert(error: $error)
    }
}

private extension ImagePickerView {
    @ViewBuilder var image: some View {
        if let selectedImage {
            selectedImage
                .resizable()
                .scaledToFit()
                .cornerRadius(8)
                .padding()
        } else {
            imagePicker
        }
    }
    
    var imagePicker: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .any(of: [.images, .not(.screenshots)]),
            photoLibrary: .shared()
        ) {
            Label("Select image", systemImage: "photo")
        }
        .buttonStyle(.borderedProminent)
        .onChange(of: selectedItem) { newItem in
            Task { await loadImage(from: newItem) }
        }
    }
    
    var operations: some View {
        VStack {
            Button("Process") {
                print("process")
            }
            
            Button("Clear", role: .destructive) {
                print("clear")
            }
        }
        .cornerRadius(8)
        .padding()
    }
    
    func loadImage(from item: PhotosPickerItem?) async {
        do {
            guard
                let data = try await item?.loadTransferable(type: Data.self),
                let uiImage = UIImage(data: data)
            else {
                throw ImagePickerError.loadingError
            }
            
            withAnimation {
                selectedImage = Image(uiImage: uiImage)
            }
        } catch {
            self.error = error is LocalizedError ? error : ImagePickerError.loadingError
            withAnimation {
                selectedImage = nil
            }
        }
    }
}

enum ImagePickerError: LocalizedError {
    case loadingError
    
    var errorDescription: String? {
        switch self {
        case .loadingError:
            return "Loading error"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .loadingError:
            return "Try choosing another image"
        }
    }
}
