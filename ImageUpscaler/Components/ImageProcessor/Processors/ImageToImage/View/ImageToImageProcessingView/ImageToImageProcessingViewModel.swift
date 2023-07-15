//
//  ImageToImageProcessingViewModel.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 09.07.2023.
//

import SwiftUI
import Combine

/// View model for the ImageToImageProcessingView.
class ImageToImageProcessingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var processingProgress: ProcessingProgress?
    @Published var processedImage: UIImage?
    @Published var state = ProcessingState.idle
    @Published var error: Error?
    
    @Published var configuration = ImageToImageConfiguration()
    
    // MARK: - Private Properties
    
    private(set) var initialImage: UIImage
    private(set) var processingType: ProcessingType
    
    private let processor = ImageToImageProcessor()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(processingType: ProcessingType, initialImage: UIImage) {
        self.processingType = processingType
        self.initialImage = initialImage
    }

    // MARK: - Public Methods
    
    /// Processes the initial image with the selected processing type and configuration.
    func process() {
        self.state = .processing
        
        processor.process(
            initialImage,
            type: processingType,
            configuration: configuration
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) { [weak self] in
                self?.processingProgress = nil
            }

            if case let .failure(error) = completion {
                if !(error is CancellationError) {
                    self?.error = error
                }
                
                self?.reset()
                
                return
            }
            
            self?.state = .finished
        } receiveValue: { [weak self] event in
            switch event {
            case .progress(let progress):
                self?.processingProgress = progress
            case .image(let uiImage):
                self?.processedImage = uiImage
            }
        }
        .store(in: &cancellables)
    }
    
    /// Cancels the processing operation.
    func cancel() {
        processor.cancel()
    }
    
    /// Resets the view model's state and clears the processed image, progress, and error.
    func reset() {
        processedImage = nil
        state = .idle
    }
    
    /// Sets up a new processing type, using the processed image as the new initial image.
    /// - Parameter processingType: The new processing type to set up.
    func setupNewProcessingType(_ processingType: ProcessingType) {
        guard let processedImage else {
            return
        }

        initialImage = processedImage
        
        error = nil
        state = .idle

        self.processingType = processingType
        self.processedImage = nil
    }
}

extension ImageToImageProcessingViewModel {
    /// Represents the processing state of the view model.
    enum ProcessingState {
        case idle
        case processing
        case finished
    }
}
