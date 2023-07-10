//
//  ImageProcessingManager.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 20.06.2023.
//

import UIKit
import Combine

import protocol Shared.MemoryOptimizable

enum ImageProcessingMethod {
    case upscaling
}

class ImageProcessorsManager: ObservableObject {
    private var processors: [String: Any] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    func getProcessor<T: Any>(for type: T.Type, create: () -> T) -> T {
        let key = String(describing: type)

        guard let processor = processors[key] as? T else {
            let newProcessor = create()
            processors[key] = newProcessor

            return newProcessor
        }
        
        return processor
    }
}

private extension ImageProcessorsManager {
    func createProcessor<T: Any>(for method: KeyPath<ImageProcessorsManager, T>) -> T {
        self[keyPath: method]
    }
}
