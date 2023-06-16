//
//  ImagesView.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 16.06.2023.
//

import SwiftUI
import PhotosUI

struct ImagesView: View {
    @ObservedObject var viewModel: ImagesViewModel
    @State private var selection = [PhotosPickerItem]()
    @State private var isEditing = false
    
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)
    
    var body: some View {
        grid
            .navigationTitle("Images")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditing ? "Done" : "Edit") {
                        withAnimation { isEditing.toggle() }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    imagePicker
                        .disabled(isEditing)
                }
            }
    }
    
    init(storage: ImagesStorageProvider) {
        viewModel = ImagesViewModel(storage: storage)
    }
}

private extension ImagesView {
    var grid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 4) {
                ForEach(viewModel.images, id: \.id) { imageInfo in
                    image(from: imageInfo)
                }
            }
            .padding(8)
        }
    }
    
    @ViewBuilder
    func image(from info: ImageInfo) -> some View {
        if let uiImage = UIImage(data: info.data) {
            Rectangle()
                .aspectRatio(1, contentMode: .fill)
                .overlay {
                    reduced(uiImage)
                        .resizable()
                        .scaledToFill()
                    
                    ZStack {
                        if isEditing {
                            Button {
                                withAnimation {
                                    viewModel.remove(info)
                                }
                            } label: {
                                Image(systemName: "xmark.square.fill")
                                    .font(.title)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, Color.red)
                            }
                        }
                    }
                }
                .cornerRadius(8)
        }
    }
    
    func reduced(_ uiImage: UIImage) -> Image {
        let maxSize = CGSize(width: 200, height: 200)
        
        let availableRect = AVFoundation.AVMakeRect(
            aspectRatio: uiImage.size, insideRect: .init(origin: .zero, size: maxSize)
        )
        
        let targetSize = availableRect.size
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        
        let resized = renderer.image { _ in
            uiImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        return Image(uiImage: resized)
    }
}

private extension ImagesView {
    var imagePicker: some View {
        PhotosPicker(
            selection: $selection,
            matching: .any(of: [.images]),
            photoLibrary: .shared()
        ) {
            Image(systemName: "plus")
        }
        .onChange(of: selection) { selectedItems in
            selection = []
            
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + .milliseconds(100)) {
                Task { await loadImages(selectedItems) }
            }
        }
        .errorAlert(error: $viewModel.error)
    }
    
    func loadImages(_ selectedItems: [PhotosPickerItem]) async {
        for item in selectedItems {
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                continue
            }
            
            withAnimation { viewModel.addImage(data) }
        }
    }
}
