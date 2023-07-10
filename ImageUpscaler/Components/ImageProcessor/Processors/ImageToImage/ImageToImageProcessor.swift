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
    var model: VNCoreMLModel?
    let modelLoder: () -> VNCoreMLModel?

    var isCurrentlyProcessing = false
        
    init(modelLoder: @escaping () -> VNCoreMLModel?) {
        self.modelLoder = modelLoder
    }

    func process(_ uiImage: UIImage) -> AnyPublisher<ProgressEvent, Error> {
        isCurrentlyProcessing = true

        let subject = PassthroughSubject<ProgressEvent, Error>()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.process(uiImage) { update in
                DispatchQueue.main.async {
                    subject.send(.updated(update))
                }
            } onCompletion: { result in
                DispatchQueue.main.async {
                    self?.isCurrentlyProcessing = false
                    
                    switch result {
                    case .success(let image):
                        subject.send(.completed(image))
                        subject.send(completion: .finished)
                        
                    case .failure(let error):
                        subject.send(completion: .failure(error))
                    }
                }
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
}

private extension ImageToImageProcessor {
    func loadModel() -> VNCoreMLModel? {
        if let model {
            return model
        }
        
        let model = modelLoder()
        self.model = model
        
        return model
    }
    
    func process(
        _ uiImage: UIImage,
        onProgress: @escaping (ProgressEventUpdate) -> Void,
        onCompletion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        onProgress(Self.modelLoadingUpdate)
        guard let model = loadModel() else {
            onCompletion(.failure(ImageToImageProcessingError.modelLoadingError))
            
            return
        }

        onProgress(Self.imagePreprocessingUpdate)
        guard
            let inputCGImage = uiImage.cgImage // needed to translate uiimage into ciimage
        else {
            onCompletion(.failure(ImageToImageProcessingError.incorrectImageData))
            
            return
        }
        
        let inputCIImage = CIImage(cgImage: inputCGImage)
        
        let inputMaxDimension = max(inputCIImage.extent.width, inputCIImage.extent.height)
        let squareCanvasSize = CGSize(width: inputMaxDimension, height: inputMaxDimension)
        
        let context = CIContext()
        let blackCanvas = CIImage(color: CIColor.black)
            .cropped(to: CGRect(origin: .zero, size: squareCanvasSize))
        let squareInputCIImage = inputCIImage.composited(over: blackCanvas)
        
        onProgress(Self.imageProcessingUpdate)
        processVNCoreMLRequest(squareInputCIImage, model: model) { result in
            switch result {
            case .success(let outputCIImage):
                onProgress(Self.imagePostprocessingUpdate)
                let outputMaxDimension = max(outputCIImage.extent.width, outputCIImage.extent.height)
                let scalingFactor = outputMaxDimension / inputMaxDimension
                
                let outputSize = inputCIImage.extent.size.applying(
                    CGAffineTransform(scaleX: scalingFactor, y: scalingFactor)
                )
                
                let croppedCIImage = outputCIImage.cropped(to: CGRect(origin: .zero, size: outputSize))
                
                guard let outputCGImage = context.createCGImage(
                    croppedCIImage,
                    from: croppedCIImage.extent
                ) else {
                    onCompletion(.failure(ImageToImageProcessingError.imagePostProcessingError))
                    
                    return
                }
                
                let outputUIImage = UIImage(
                    cgImage: outputCGImage,
                    scale: 1,
                    orientation: uiImage.imageOrientation
                )
                
                onProgress(Self.completedUpdate)
                onCompletion(.success(outputUIImage))
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }
    
    func processVNCoreMLRequest(
        _ ciImage: CIImage,
        model: VNCoreMLModel,
        completion: @escaping (Result<CIImage, Error>) -> Void
    ) {
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                completion(.failure(error))
                
                return
            }
            
            guard
                let results = request.results as? [VNPixelBufferObservation],
                let outputPixelBuffer = results.first?.pixelBuffer
            else {
                completion(.failure(ImageToImageProcessingError.coreMLRequestError))

                return
            }
            
            let outputCIImage = CIImage(cvPixelBuffer: outputPixelBuffer)
            
            completion(.success(outputCIImage))
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        try? handler.perform([request]) // errors will be handled in continuation
    }
}

private extension ImageToImageProcessor {
    static let initializingUpdate = ProgressEventUpdate(
        message: "Initializing",
        completionRatio: 0
    )
        
    static let modelLoadingUpdate = ProgressEventUpdate(
        message: "Loading model. This may take some time on first launch",
        completionRatio: 1/5
    )
    
    static let imagePreprocessingUpdate = ProgressEventUpdate(
        message: "Preprocessing operations",
        completionRatio: 2/5
    )
    
    static let imageProcessingUpdate = ProgressEventUpdate(
        message: "Processing image",
        completionRatio: 3/5
    )
    
    static let imagePostprocessingUpdate = ProgressEventUpdate(
        message: "Postprocessing operations",
        completionRatio: 4/5
    )
    
    static let completedUpdate = ProgressEventUpdate(
        message: "Completed!",
        completionRatio: 1
    )
}

enum ImageToImageProcessingError: Error {
    case modelLoadingError
    case incorrectImageData
    case coreMLRequestError
    case imagePostProcessingError
}
