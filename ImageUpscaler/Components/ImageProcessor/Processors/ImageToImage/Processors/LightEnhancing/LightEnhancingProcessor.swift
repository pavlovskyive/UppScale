//
//  LightEnhancingProcessor.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 10.07.2023.
//

import CoreML
import Vision
import Combine
import CoreImage

import class SwiftUI.UIImage

final class LightEnhancingProcessor: ImageToImageProcessor {
    private let upscalingProcessor: UpscalingProcessor?
    
    init(upscalingProcessor: UpscalingProcessor? = nil) {
        self.upscalingProcessor = upscalingProcessor
        super.init {
            let configuration = MLModelConfiguration()
            let coreMLModel = try Zero_DCE(configuration: configuration)
            let visionModel = try VNCoreMLModel(for: coreMLModel.model)
            
            return visionModel
        }
    }
    
//    override func process(_ uiImage: UIImage) -> AnyPublisher<ProgressEvent, Error> {
//        let subject = PassthroughSubject<ProgressEvent, Error>()
//
//        Task {
//            do {
//                try await super.processImage(uiImage, subject: subject)
//            } catch {
//                subject.send(completion: .failure(error))
//            }
//        }
//
//        return subject
//            .flatMap { [weak self] progressEvent -> AnyPublisher<ProgressEvent, Error> in
//                guard let self = self else {
//                    return Empty().eraseToAnyPublisher()
//                }
//
//                switch progressEvent {
//                case .completed(let lightEnhancedImage):
//                    if let upscalingProcessor = self.upscalingProcessor {
//                        return upscalingProcessor.process(lightEnhancedImage)
//                            .eraseToAnyPublisher()
//                    } else {
//                        return Just(.completed(lightEnhancedImage))
//                            .setFailureType(to: Error.self)
//                            .eraseToAnyPublisher()
//                    }
//                case .updated:
//                    return Just(progressEvent)
//                        .setFailureType(to: Error.self)
//                        .eraseToAnyPublisher()
//                }
//            }
//            .eraseToAnyPublisher()
//    }
}
