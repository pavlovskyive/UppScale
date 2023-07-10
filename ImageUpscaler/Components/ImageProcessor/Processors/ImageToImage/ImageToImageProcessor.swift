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
import class SwiftUI.UIImage

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

        Task(priority: .userInitiated) { [weak self] in
            guard let self = self else {
                subject.send(completion: .finished)

                return
            }

            do {
                let steps = postProcessor != nil ? 2 : 1

                var processedImage = try await self.processImage(
                    uiImage,
                    step: 1,
                    of: steps
                ) { update in
                    subject.sendOnMain(.updated(update))
                }

                if let postProcessor {
                    processedImage = try await postProcessor.processImage(
                        processedImage,
                        step: 2,
                        of: steps
                    ) { update in
                        subject.sendOnMain(.updated(update))
                    }
                }
                
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
        let inputCIImageExtent = originalUIImage.ciImage?.extent
            ?? CGRect(origin: .zero, size: originalUIImage.size)
        
        let outputMaxDimension = max(outputCIImage.extent.width, outputCIImage.extent.height)

        let scalingFactor = outputMaxDimension
            / max(inputCIImageExtent.width, inputCIImageExtent.height)
        
        let outputSize = inputCIImageExtent.size.applying(
            CGAffineTransform(scaleX: scalingFactor, y: scalingFactor)
        )

        guard let outputCGImage = CIContext().createCGImage(
            outputCIImage,
            from: CGRect(origin: .zero, size: outputSize)
        ) else {
            throw ImageToImageProcessingError.imagePostProcessingError
        }

        return UIImage(
            cgImage: outputCGImage,
            scale: 1,
            orientation: originalUIImage.imageOrientation
        )
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
