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
    
    init(modelLoader: @escaping () throws -> VNCoreMLModel) {
        self.modelLoader = modelLoader
    }
    
    func process(
        _ uiImage: UIImage,
        postProcessor: ImageToImageProcessor? = nil
    ) -> AnyPublisher<ProgressEvent, Error> {
        isCurrentlyProcessing = true
        let subject = PassthroughSubject<ProgressEvent, Error>()
        let tileSize = CGSize(width: 512, height: 512)
        
        Task(priority: .userInitiated) { [weak self] in
            guard let self = self else {
                subject.send(completion: .finished)
                return
            }
            
            do {
                // Create tiles
                let tilesWithPositions = uiImage.tiles(tileSize)
                var processedTilesWithPositions = [TileWithPosition]()
                
                for (index, tileWithPosition) in tilesWithPositions.enumerated() {
                    let processedTile = try await self.processImage(
                        tileWithPosition.tile,
                        step: index + 1,
                        of: tilesWithPositions.count
                    ) { update in
                        subject.sendOnMain(.updated(update))
                    }
                    processedTilesWithPositions.append(TileWithPosition(tile: processedTile, position: tileWithPosition.position))
                }
                
                // Stitch tiles back together
                let processedImage = UIImage.stitch(tiles: processedTilesWithPositions, originalImage: uiImage, originalTileSize: tileSize)!
                
                subject.sendOnMain(.updated(ProgressEventUpdate(message: "Completed!", completionRatio: 1)))
                subject.sendOnMain(.completed(processedImage))
                subject.sendOnMain(completion: .finished)
            } catch {
                subject.sendOnMain(completion: .failure(error))
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    func processImage(
        _ uiImage: UIImage,
        step: Int,
        of steps: Int,
        onProgressUpdate: (ProgressEventUpdate) -> Void
    ) async throws -> UIImage {
        onProgressUpdate(eventUpdate(for: .modelLoading, step: step, of: steps))
        
        let model = try loadModel()
        
        onProgressUpdate(eventUpdate(for: .preprocessing, step: step, of: steps))
        
        guard let inputCIImage = uiImage.cgImage.map({ CIImage(cgImage: $0) }) else {
            throw ImageToImageProcessingError.incorrectImageData
        }
        
        let squareInputCIImage = preprocessImage(inputCIImage)
        
        onProgressUpdate(eventUpdate(for: .processing, step: step, of: steps))
        
        let outputCIImage = try process(squareInputCIImage, model: model)
        
        onProgressUpdate(eventUpdate(for: .postprocessing, step: step, of: steps))
        
        let outputUIImage = try postProcessImage(outputCIImage, originalUIImage: uiImage)
        
        return outputUIImage
    }
    
    private func loadModel() throws -> VNCoreMLModel {
        if let model {
            return model
        }
        
        let model = try modelLoader()
        self.model = model
        
        return model
    }
    
    func preprocessImage(_ inputCIImage: CIImage) -> CIImage {
        let inputMaxDimension = max(inputCIImage.extent.width, inputCIImage.extent.height)
        let squareCanvasSize = CGSize(width: inputMaxDimension, height: inputMaxDimension)
        
        let blackCanvas = CIImage(color: CIColor.black)
            .cropped(to: CGRect(origin: .zero, size: squareCanvasSize))
        
        return inputCIImage.composited(over: blackCanvas)
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
    
    func postProcessImage(
        _ outputCIImage: CIImage,
        originalUIImage: UIImage
    ) throws -> UIImage {
        guard let inputCIImage = originalUIImage.cgImage.map({ CIImage(cgImage: $0) }) else {
            throw ImageToImageProcessingError.imagePostProcessingError
        }
        
        let outputMaxDimension = max(outputCIImage.extent.width, outputCIImage.extent.height)
        
        let scalingFactor = outputMaxDimension
        / max(inputCIImage.extent.width, inputCIImage.extent.height)
        
        let outputSize = inputCIImage.extent.size.applying(
            CGAffineTransform(scaleX: scalingFactor, y: scalingFactor)
        )
        
        guard let outputCGImage = CIContext().createCGImage(
            outputCIImage,
            from: CGRect(origin: .zero, size: outputSize)
        ) else {
            throw ImageToImageProcessingError.imagePostProcessingError
        }
        
        return UIImage(cgImage: outputCGImage)
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

struct TileWithPosition {
    let tile: UIImage
    let position: CGPoint
}

extension UIImage {
    func tiles(_ tileSize: CGSize) -> [TileWithPosition] {
        guard let cgImage = self.cgImage else {
            return []
        }
        
        let width = Int(cgImage.width)
        let height = Int(cgImage.height)
        
        let tileWidth = Int(tileSize.width)
        let tileHeight = Int(tileSize.height)

        var tilesWithPositions = [TileWithPosition]()
        
        for y in stride(from: 0, to: height, by: Int(tileSize.height)) {
            for x in stride(from: 0, to: width, by: Int(tileSize.width)) {

                let tileWidth = Int(tileSize.width)
                let tileHeight = Int(tileSize.height)

                // Adjust x and y if the tile exceeds the image boundaries
                let finalX = min(x, width - tileWidth)
                let finalY = min(y, height - tileHeight)

                let tileRect = CGRect(x: finalX, y: finalY, width: tileWidth, height: tileHeight)
                if let tile = cgImage.cropping(to: tileRect) {
                    let tileImage = UIImage(cgImage: tile)
                    tilesWithPositions.append(TileWithPosition(tile: tileImage, position: CGPoint(x: finalX, y: finalY)))
                }
            }
        }
        
        return tilesWithPositions
    }
}

extension UIImage {
    static func stitch(tiles: [TileWithPosition], originalImage: UIImage, originalTileSize: CGSize) -> UIImage? {
        let originalSize = originalImage.size
        let tileSize = tiles.first?.tile.size ?? CGSize.zero
        let scalingFactor = tileSize.width / originalTileSize.width
        let maxDimension = max(originalSize.width, originalSize.height)
        
        let canvasSize = CGSize(width: maxDimension, height: maxDimension)
            .applying(CGAffineTransform(scaleX: scalingFactor, y: scalingFactor))
        
        print("-> originalSize: \(originalSize)")
        print("-> tileSize: \(tileSize)")
        print("-> scalingFactor: \(scalingFactor)")
        print("-> maxDimension: \(maxDimension)")
        print("-> canvasSize: \(canvasSize)")
        
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        
        let stitchedImage = renderer.image { context in
            context.cgContext.translateBy(x: 0, y: canvasSize.height)
            context.cgContext.scaleBy(x: 1, y: -1)
            
            tiles.forEach { tileWithPosition in
                guard let cgImage = tileWithPosition.tile.cgImage else {
                    return
                }
                
                let rect = CGRect(
                    x: tileWithPosition.position.x * scalingFactor,
                    y: canvasSize.height - tileWithPosition.position.y * scalingFactor - tileSize.height,
                    width: tileSize.width,
                    height: tileSize.height
                )
                
                context.cgContext.draw(cgImage, in: rect)
            }
        }
        
        // Apply image orientation
        guard let stitchedImageCGImage = stitchedImage.cgImage else {
            return nil
        }
        
        let orientedImage = UIImage(
            cgImage: stitchedImageCGImage,
            scale: originalImage.scale,
            orientation: originalImage.imageOrientation
        )
        
        let outputMaxDimension = max(orientedImage.size.width, orientedImage.size.height)
        let outScaling = outputMaxDimension / maxDimension
        
        let outputSize = originalSize.applying(
            CGAffineTransform(scaleX: outScaling, y: outScaling)
        )
        
        // Calculate crop rect based on the original image orientation
        var cropRect = CGRect.zero
        switch originalImage.imageOrientation {
        case .up, .upMirrored, .down, .downMirrored:
            cropRect = CGRect(x: 0, y: 0, width: outputSize.width, height: outputSize.height)
        case .left, .leftMirrored, .right, .rightMirrored:
            cropRect = CGRect(x: 0, y: 0, width: outputSize.height, height: outputSize.width)
        @unknown default:
            break
        }
        
        // Perform the crop
        if let croppedCGImage = orientedImage.cgImage?.cropping(to: cropRect) {
            return UIImage(
                cgImage: croppedCGImage,
                scale: originalImage.scale,
                orientation: originalImage.imageOrientation
            )
        } else {
            return nil
        }
    }
}
