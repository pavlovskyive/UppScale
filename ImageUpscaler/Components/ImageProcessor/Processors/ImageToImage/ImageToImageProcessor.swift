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
    private let modelLoader: () throws -> VNCoreMLModel
    
    private var isCurrentlyProcessing = false
    private var isCanceled = false
    
    init(modelLoader: @escaping () throws -> VNCoreMLModel) {
        self.modelLoader = modelLoader
    }
    
    /// Combine API for processing image.
    func process(
        _ uiImage: UIImage,
        tileSize: Int = 1024,
        overlap: CGFloat = 0.2
    ) -> AnyPublisher<ProgressEvent, Error> {
        let subject = PassthroughSubject<ProgressEvent, Error>()
        
        isCurrentlyProcessing = true
        
        Task {
            do {
                try await processImage(
                    uiImage,
                    tileSize: tileSize,
                    overlap: overlap
                ) { update in
                    subject.sendOnMain(update)
                }
                
                subject.sendOnMain(completion: .finished)
            } catch {
                subject.sendOnMain(completion: .failure(error))
            }
            
            await MainActor.run {
                isCurrentlyProcessing = false
                
                print("-> Not processing anymoressing")
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    // Callback API for processing image.
    func processImage(
        _ uiImage: UIImage,
        tileSize: Int,
        overlap: CGFloat,
        onProgressUpdate: (ProgressEvent) -> Void
    ) async throws {
        onProgressUpdate(.updated(ProgressEventUpdate(
            message: "Loading model", completionRatio: 0
        )))
        
        let model = try loadModel()
        
        guard let uiImage = uiImage.withFixedOrientation else {
            throw ImageToImageProcessingError.incorrectImageData
        }
        
        var tileSize = tileSize
        
        guard let tiles = uiImage.tiles(overlap: overlap, tileSize: &tileSize) else {
            throw ImageToImageProcessingError.tilingError
        }
        
        var outputImage = uiImage
        
        let ciContext = CIContext()
        
        for (index, tile) in tiles.enumerated() {
            guard !isCanceled else {
                isCanceled = false
                onProgressUpdate(.updated(ProgressEventUpdate(
                    message: "Canceled",
                    completionRatio: 1
                )))
                onProgressUpdate(.canceled)
                
                return
            }
            
            onProgressUpdate(.updated(ProgressEventUpdate(
                message: "[\(index + 1)/\(tiles.count)] Processing",
                completionRatio: Double(index) / Double(tiles.count)
            )))
            
            let ciImage = CIImage(cgImage: tile.image)
            let processedCIImage = try process(ciImage, model: model)
            
            guard
                let cgImage = processedCIImage.cgImage(context: ciContext)?.withFixedOrientation
            else {
                throw ImageToImageProcessingError.incorrectImageData
            }
            
            let processedTile = Tile(image: cgImage, rect: tile.rect)
            outputImage = outputImage.withPlaced(tile: processedTile)
            
            onProgressUpdate(.updatedImage(outputImage))
            
            // HACK: Overall better performance with sleep smh.
            try await Task.sleep(for: .milliseconds(300))
        }
        
        onProgressUpdate(.updated(ProgressEventUpdate(
            message: "Complete!",
            completionRatio: 1
        )))
    }
    
    func cancel() {
        isCanceled = true
    }
}

private extension ImageToImageProcessor {
    func loadModel() throws -> VNCoreMLModel {
        if let model {
            return model
        }
        
        let model = try modelLoader()
        self.model = model
        
        return model
    }
    
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

enum ImageToImageProcessingError: Error {
    case modelLoadingError
    case incorrectImageData
    case tilingError
    case visionRequestError
    case imagePostprocessingError
}
