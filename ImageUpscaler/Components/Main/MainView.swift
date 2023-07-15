//
//  MainView.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 17.06.2023.
//

import SwiftUI
import PhotosUI

// MARK: - ImageInfoSpec

/// A structure representing image information.
private struct ImageInfoSpec: Hashable {
    let id = UUID()
    let image: UIImage
}

// MARK: - MainView

/// The main view of the application.
struct MainView: View {
    @State private var selection: PhotosPickerItem?
    @State private var path = NavigationPath()
    @State private var processingType = ProcessingType.upscaling
    @State private var photosPickerPresented = false
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                mainContent
            }
            .background(.background)
            .photosPicker(
                isPresented: $photosPickerPresented,
                selection: $selection,
                matching: .all(of: [.images]),
                photoLibrary: .shared()
            )
            .onChange(of: selection) { selectedItem in
                handleSelection(selectedItem)
            }
            .navigationDestination(for: ImageInfoSpec.self) { imageInfo in
                destinationView(for: imageInfo)
            }
        }
    }
}

// MARK: - MainView Private Views

private extension MainView {
    var mainContent: some View {
        VStack(spacing: 16) {
            imagePicker(for: .upscaling)
            imagePicker(for: .lightEnhancing)
        }
        .padding(.horizontal, 16)
    }
    
    func imagePicker(for processingType: ProcessingType) -> some View {
        ProcessingInfoCard(processingType: processingType)
            .onTapGesture {
                self.processingType = processingType
                self.photosPickerPresented.toggle()
            }
    }
    
    func destinationView(for imageInfo: ImageInfoSpec) -> some View {
        ImageToImageProcessingView(processingType: processingType, uiImage: imageInfo.image)
    }
}

// MARK: - MainView Private Methods

private extension MainView {
    func handleSelection(_ selectedItem: PhotosPickerItem?) {
        Task {
            guard let data = try? await selectedItem?.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                print("Failed to load image")
                return
            }
            
            await MainActor.run {
                let imageInfo = ImageInfoSpec(image: image)
                path.append(imageInfo)
            }
        }
    }
}

// MARK: - MainView_Previews

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MainView()
        }
    }
}
