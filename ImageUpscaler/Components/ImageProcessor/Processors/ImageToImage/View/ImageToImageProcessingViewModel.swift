//
//  ImageToImageProcessingViewModel.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 09.07.2023.
//

import SwiftUI
import Combine

class ImageToImageProcessingViewModel: ObservableObject {
    @Published var progressUpdate: ProgressEventUpdate?
    @Published var processedImage: UIImage?
    @Published var isBusy = false
    @Published var error: Error?
    
    @Published var configuration = ImageToImageConfiguration()
    
    private let processor: ImageToImageProcessor
    private let postProcessor: ImageToImageProcessor?
    let initialImage: UIImage
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        processor: ImageToImageProcessor,
        postProcessor: ImageToImageProcessor? = nil,
        uiImage: UIImage
    ) {
        self.processor = processor
        self.postProcessor = postProcessor
        self.initialImage = uiImage
    }
    
    func process() {
        self.isBusy = true
        
        processor.process(
            initialImage,
            configuration: configuration
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            if case let .failure(error) = completion {
                self?.error = error
            }
            
            self?.isBusy = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) { [weak self] in
                self?.progressUpdate = nil
            }
        } receiveValue: { [weak self] event in
            switch event {
            case .updated(let progressUpdate):
                self?.progressUpdate = progressUpdate
            case .updatedImage(let uiImage):
                self?.processedImage = uiImage
            case .canceled:
                self?.processedImage = nil
            }
        }
        .store(in: &cancellables)
    }
    
    func cancel() {
        processor.cancel()
    }
}
