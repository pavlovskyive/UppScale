//
//  ImageToImageProcessor.swift
//
//
//  Created by Vsevolod Pavlovskyi on 25.06.2023.
//

import CoreML
import CoreImage
import Vision
import Combine
import SwiftUI

class ImageToImageProcessor {
    private var model: VNCoreMLModel?
    private let modelLoader: () throws -> VNCoreMLModel
    
    private var isCurrentlyProcessing = false
    private var isCanceled = false
    
    init(modelLoader: @escaping () throws -> VNCoreMLModel) {
        self.modelLoader = modelLoader
    }
    
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
    
    func cancel() {
        isCanceled = true
    }
    
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
        
        guard let uiImage = uiImage.withFixedOrientation() else {
            throw ImageToImageProcessingError.incorrectImageData // TODO: change
        }
        
        var tileSize = tileSize
        
        let tiles = try uiImage.tiles(overlap: overlap, tileSize: &tileSize)
        
        let ciContext = CIContext()
        
        var outputImage = uiImage
        
        for (index, tile) in tiles.enumerated() {
            guard !isCanceled else {
                isCanceled = false
                
                throw ImageToImageProcessingError.coreMLRequestResultError // TODO: change to canceled
            }
            
            onProgressUpdate(.updated(ProgressEventUpdate(
                message: "[\(index + 1)/\(tiles.count)] Processing",
                completionRatio: Double(index) / Double(tiles.count)
            )))

            let ciImage = CIImage(cgImage: tile.image)
            var processedCIImage = try process(ciImage, model: model)
            
            let postprocessedCGImage = try postprocessImage(processedCIImage)
            
            let processedTile = Tile(image: postprocessedCGImage, rect: tile.rect)
            outputImage = outputImage.placed(tile: processedTile)

            onProgressUpdate(.updatedImage(outputImage))
            
            try await Task.sleep(for: .milliseconds(300))
        }
        
        onProgressUpdate(.updated(ProgressEventUpdate(
            message: "Complete!",
            completionRatio: 1
        )))
    }
    
    private func loadModel() throws -> VNCoreMLModel {
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
            throw ImageToImageProcessingError.coreMLRequestResultError
        }
        
        let outputCIImage = CIImage(cvPixelBuffer: outputPixelBuffer)
        
        return outputCIImage
    }
    
    func postprocessImage(
        _ ciImage: CIImage
    ) throws -> CGImage {
        guard let cgImage = CIContext().createCGImage(
            ciImage,
            from: ciImage.extent
        ) else {
            throw ImageToImageProcessingError.imagePostProcessingError // TODO: change
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        let cgContext = CGContext(
            data: nil,
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: cgImage.bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )
        
        guard let cgContext else {
            throw ImageToImageProcessingError.imagePostProcessingError // TODO: change
        }
        
        // Translate to flip image
        cgContext.translateBy(x: 0, y: CGFloat(cgImage.height))
        cgContext.scaleBy(x: 1, y: -1)
        
        cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        
        guard let cgImage = cgContext.makeImage() else {
            throw ImageToImageProcessingError.imagePostProcessingError // TODO: change
        }
        
        return cgImage
    }
}

extension ImageToImageProcessor {
    enum ProcessingEvent: Int, CaseIterable {
        case modelLoading = 0
        case preprocessing
        case processing
        case postprocessing
        
        var title: String {
            switch self {
            case .modelLoading:
                return "Loading model. This may take some time on first launch"
            case .preprocessing:
                return "Preprocessing"
            case .processing:
                return "Processing"
            case .postprocessing:
                return "Postprocessing"
            }
        }
    }
    
    func eventUpdate(
        for event: ProcessingEvent,
        step: Int,
        of steps: Int
    ) -> ProgressEventUpdate {
        let totalEvents = ProcessingEvent.allCases.count
        let totalSteps = steps * totalEvents
        let currentStep = (step - 1) * totalEvents + event.rawValue
        let completionRatio = Double(currentStep) / Double(totalSteps)
        
        return ProgressEventUpdate(
            message: "[\(step)/\(steps)] \(event.title)",
            completionRatio: completionRatio
        )
    }
}

enum ImageToImageProcessingError: Error {
    case modelLoadingError
    case incorrectImageData
    case coreMLRequestResultError
    case imagePostProcessingError
}

extension PassthroughSubject {
    func sendOnMain(_ value: Output) {
        DispatchQueue.main.async {
            self.send(value)
        }
    }
    
    func sendOnMain(completion: Subscribers.Completion<Failure>) {
        DispatchQueue.main.async {
            self.send(completion: completion)
        }
    }
}

struct Tile {
    let image: CGImage
    let rect: CGRect
}

extension UIImage {
    func tiles(
        maxTileCount: Int = 20,
        overlap: CGFloat = 1 / 4,
        tileSize: inout Int
    ) throws -> [Tile] {
        guard let cgImage = self.cgImage else {
            throw ImageToImageProcessingError.incorrectImageData
        }
        
        let width = Int(cgImage.width)
        let height = Int(cgImage.height)
        
        tileSize = min(tileSize, width, height)
        
        let overlappedTileSize = Double(tileSize) * (1.0 - overlap)
        let overlapSize = Int(Double(tileSize) * overlap)
        
        var tiles = [Tile]()
        
        for y in stride(from: 0, to: height, by: tileSize - overlapSize) {
            for x in stride(from: 0, to: width, by: tileSize - overlapSize) {
                let finalX = min(x, width - tileSize)
                let finalY = min(y, height - tileSize)
                
                let cgTileRect = CGRect(x: finalX, y: finalY, width: tileSize, height: tileSize)
                
                guard let image = cgImage.cropping(to: cgTileRect) else {
                    throw ImageToImageProcessingError.incorrectImageData
                }
                
                // Convert the y-coordinate to UIKit's coordinate system
                let uiKitY = height - finalY - tileSize
                
                let uiKitTileRect = CGRect(x: finalX, y: uiKitY, width: tileSize, height: tileSize)
                
                let tile = Tile(
                    image: image,
                    rect: uiKitTileRect
                )
                
                tiles.append(tile)
            }
        }
        
        return tiles
    }
}


extension UIImage {
    func placed(tile: Tile) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let newImage = renderer.image { context in
            context.cgContext.interpolationQuality = .high
            context.cgContext.setShouldAntialias(true)
            
            // Draw the original image onto the context
            draw(in: CGRect(origin: .zero, size: size))

            // Flip the tile image vertically
            let flippedTileImage = tile.image
            
            // Adjust y position to UIKit coordinate system
            let adjustedY = size.height - tile.rect.origin.y - tile.rect.height
            let adjustedRect = CGRect(x: tile.rect.origin.x, y: adjustedY, width: tile.rect.width, height: tile.rect.height)

            // Draw the tile onto the original image
            context.cgContext.draw(flippedTileImage, in: adjustedRect)
        }

        return newImage
    }
}

extension UIImage {
    func withFixedOrientation() -> UIImage? {
        switch imageOrientation {
        case .up:
            return self
        default:
            let renderer = UIGraphicsImageRenderer(size: size, format: .init(for: traitCollection))

            return renderer.image { _ in
                draw(in: CGRect(origin: .zero, size: size))
            }
        }
    }
}
