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

class ImageToImageProcessor {
    private var model: VNCoreMLModel?

    private var currentTask: Task<Void, Error>?
    
    /// Combine API for processing image.
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
            } catch is CancellationError {
                subject.sendOnMain(.cancel)
                subject.sendOnMain(completion: .finished)
            } catch {
                subject.sendOnMain(completion: .failure(error))
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    // Callback API for processing image.
    func processImage(
        _ uiImage: UIImage,
        type: ProcessingType,
        configuration: ImageToImageConfiguration = ImageToImageConfiguration(),
        onProgressUpdate: (ProcessingUpdate) -> Void
    ) async throws {
        onProgressUpdate(.progress(.modelLoading))
        
        let model = try type.loadModel()
        
        guard let uiImage = uiImage.withFixedOrientation else {
            throw ImageToImageProcessingError.incorrectImageData
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
                throw ImageToImageProcessingError.incorrectImageData
            }
            
            if index == 0 {
                scalingFactor = CGFloat(cgImage.width) / CGFloat(tile.image.width)
                
                guard
                    let resizedImage = outputImage.resized(to: outputImage.size * scalingFactor)
                else {
                    throw ImageToImageProcessingError.incorrectImageData
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
        
        onProgressUpdate(.progress(.complete))
    }
    
    func cancel() {
        currentTask?.cancel()
    }
}

private extension ImageToImageProcessor {
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
            throw ImageToImageProcessingError.visionRequestError
        }
        
        let outputCIImage = CIImage(cvPixelBuffer: outputPixelBuffer)
        
        return outputCIImage
    }
}

private extension ProcessingProgress {
    static var modelLoading: Self {
        ProcessingProgress(message: "Loading model", completionRatio: 0)
    }

    static var complete: Self {
        ProcessingProgress(message: "Completed!", completionRatio: 1)
    }
    
    static func processingTile(_ index: Int, of count: Int) -> Self {
        ProcessingProgress(
            message: "[\(index)/\(count)] Processing",
            completionRatio: Double(index) / Double(count)
        )
    }
}
