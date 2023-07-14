//
//  ImageToImageProcessingViewModel.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 09.07.2023.
//

import SwiftUI
import Combine

class ImageToImageProcessingViewModel: ObservableObject {
    @Published var processingProgress: ProcessingProgress?
    @Published var processedImage: UIImage?
    @Published var isBusy = false
    @Published var error: Error?
    
    @Published var configuration = ImageToImageConfiguration()
    
    let initialImage: UIImage
    private let processingType: ProcessingType

    private let processor = ImageToImageProcessor()
    private var cancellables = Set<AnyCancellable>()
    
    init(processingType: ProcessingType, initialImage: UIImage) {
        self.processingType = processingType
        self.initialImage = initialImage
    }
    
    func process() {
        self.isBusy = true
        
        processor.process(
            initialImage,
            type: processingType,
            configuration: configuration
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            if case let .failure(error) = completion {
                self?.error = error
                self?.processedImage = nil
            }
            
            self?.isBusy = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) { [weak self] in
                self?.processingProgress = nil
            }
        } receiveValue: { [weak self] event in
            switch event {
            case .progress(let progress):
                self?.processingProgress = progress
            case .image(let uiImage):
                self?.processedImage = uiImage
            case .cancel:
                self?.processedImage = nil
                self?.processingProgress = ProcessingProgress(message: "Canceled")
            }
        }
        .store(in: &cancellables)
    }
    
    func cancel() {
        processor.cancel()
    }
}
