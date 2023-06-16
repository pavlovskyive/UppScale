//
//  ImagesViewModel.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 16.06.2023.
//

import SwiftUI

class ImagesViewModel: ObservableObject {
    private let storage: ImagesStorageProvider

    @Published var images = [ImageInfo]()
    @Published var error: Error?
    
    init(storage: ImagesStorageProvider) {
        self.storage = storage
        
        loadImages()
    }
    
    func addImage(_ imageData: Data) {
        let imageInfo = ImageInfo(data: imageData)
        self.images.append(imageInfo)
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            try? self?.storage.addImages([imageInfo])
        }
    }
    
    func remove(_ imageInfo: ImageInfo) {
        self.images.removeAll(where: { $0.id == imageInfo.id })
        
        do {
            try storage.deleteImages([imageInfo])
        } catch {
            self.error = error
        }
    }
}

private extension ImagesViewModel {
    func loadImages() {
        do {
            images = try storage.fetchImages()
        } catch {
            self.error = error
        }
    }
}
