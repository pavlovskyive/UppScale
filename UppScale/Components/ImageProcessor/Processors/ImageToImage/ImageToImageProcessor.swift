//
//  ImageToImageProcessor.swift
//
//
//  Created by Vsevolod Pavlovskyi on 25.06.2023.
//

import class UIKit.UIImage
import CoreImage
import Vision
import Combine

/// A class that performs image-to-image processing using Core ML models.
class ImageToImageProcessor {
    private var model: VNCoreMLModel?
    private var currentTask: Task<Void, Error>?
    
    /// Processes the given UIImage using the specified processing type and configuration.
    /// Returns a publisher that emits processing updates and errors.
    ///
    /// - Parameters:
    ///   - uiImage: The input UIImage to process.
    ///   - type: The processing type.
    ///   - configuration: The image-to-image configuration.
    /// - Returns: A publisher that emits processing updates and errors.
    func process(
        _ uiImage: UIImage,
        type: ProcessingType,
        configuration: ImageToImageConfiguration = ImageToImageConfiguration()
    ) -> AnyPublisher<ProcessingUpdate, Error> {
        let subject = PassthroughSubject<ProcessingUpdate, Error>()
        currentTask?.cancel()

        currentTask = Task.detached { [weak self] in
            do {
                try await self?.processImage(
                    uiImage,
                    type: type,
                    configuration: configuration
                ) { update in
                    subject.sendOnMain(update)
                }
                
                subject.sendOnMain(completion: .finished)
            } catch {
                if error is CancellationError {
                    subject.sendOnMain(.progress(.canceled))
                }

                subject.sendOnMain(completion: .failure(error))
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Callback API
    
    /// Processes the given UIImage using the specified processing type and configuration,
    /// and invokes the progress update callback with processing updates.
    ///
    /// - Parameters:
    ///   - uiImage: The input UIImage to process.
    ///   - type: The processing type.
    ///   - configuration: The image-to-image configuration.
    ///   - onProgressUpdate: The callback to receive processing updates.
    /// - Throws: An error if processing fails.
    func processImage(
        _ uiImage: UIImage,
        type: ProcessingType,
        configuration: ImageToImageConfiguration = ImageToImageConfiguration(),
        onProgressUpdate: (ProcessingUpdate) -> Void
    ) async throws {
        onProgressUpdate(.progress(.modelLoading))
        
        let model = try type.loadModel()
        
        guard let uiImage = uiImage.withFixedOrientation else {
            throw ImageToImageProcessingError.invalidData
        }
        
        var tileSize = configuration.tileSize
        
        guard let tiles = uiImage.tiles(
            overlap: configuration.overlap,
            tileSize: &tileSize
        ) else {
            throw ImageToImageProcessingError.tilingError
        }
        
        var outputImage = uiImage
        
        let ciContext = CIContext()
        
        var scalingFactor = 1.0
        
        for (index, tile) in tiles.enumerated() {
            onProgressUpdate(.progress(.processingTile(index, of: tiles.count)))
            
            let ciImage = CIImage(cgImage: tile.image)
            let processedCIImage = try process(ciImage, model: model)
            
            guard
                let cgImage = processedCIImage.cgImage(context: ciContext)?.withFixedOrientation
            else {
                throw ImageToImageProcessingError.invalidData
            }
            
            if index == 0 {
                scalingFactor = CGFloat(cgImage.width) / CGFloat(tile.image.width)
                
                guard
                    let resizedImage = outputImage.resized(to: outputImage.size * scalingFactor)
                else {
                    throw ImageToImageProcessingError.invalidData
                }
                
                outputImage = resizedImage
            }
            
            let resizedRect = tile.rect * scalingFactor
            
            let processedTile = Tile(image: cgImage, rect: resizedRect.integral)
            
            outputImage = outputImage.withPlaced(tile: processedTile)
            
            onProgressUpdate(.image(outputImage))
            
            // HACK: Overall improved stability with sleep smh.
            try await Task.sleep(for: .milliseconds(300))
        }
        
        onProgressUpdate(.progress(.completed))
    }
    
    /// Cancels the currently running image processing task.
    func cancel() {
        currentTask?.cancel()
    }
}

private extension ImageToImageProcessor {
    /// Processes the input CIImage using the specified Core ML model.
    ///
    /// - Parameters:
    ///   - inputCIImage: The input CIImage to process.
    ///   - model: The Core ML model to use for processing.
    /// - Returns: The processed CIImage.
    /// - Throws: An error if processing fails.
    func process(
        _ inputCIImage: CIImage,
        model: VNCoreMLModel
    ) throws -> CIImage {
        let request = VNCoreMLRequest(model: model)
        try VNImageRequestHandler(ciImage: inputCIImage).perform([request])
        guard
            let results = request.results as? [VNPixelBufferObservation],
            let outputPixelBuffer = results.first?.pixelBuffer
        else {
            throw ImageToImageProcessingError.processingError
        }
        
        let outputCIImage = CIImage(cvPixelBuffer: outputPixelBuffer)
        
        return outputCIImage
    }
}

private extension ProcessingProgress {
    /// A processing progress indicating that the model is loading.
    static var modelLoading: Self {
        ProcessingProgress(message: "processing.update.modelLoading".localized, completionRatio: 0)
    }

    /// A processing progress indicating that the processing is complete.
    static var completed: Self {
        ProcessingProgress(message: "processing.update.completed".localized, completionRatio: 1)
    }
    
    static var canceled: Self {
        ProcessingProgress(message: "processing.update.canceled".localized)
    }
    
    /// Creates a processing progress for a specific tile during processing.
    ///
    /// - Parameters:
    ///   - index: The index of the tile.
    ///   - count: The total number of tiles.
    /// - Returns: A processing progress for the tile.
    static func processingTile(_ index: Int, of count: Int) -> Self {
        ProcessingProgress(
            message: "[\(index)/\(count)] \("processing.update.processingTile".localized)",
            completionRatio: Double(index) / Double(count)
        )
    }
}
