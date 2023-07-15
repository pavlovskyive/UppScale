//
//  Subject+SendOnMain.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 13.07.2023.
//

import Foundation
import Combine

extension Subject where Failure == Error {
    /// Sends the specified value on the main queue.
    ///
    /// - Parameter value: The value to send.
    func sendOnMain(_ value: Output) {
        DispatchQueue.main.async {
            self.send(value)
        }
    }
    
    /// Sends the specified completion on the main queue.
    ///
    /// - Parameter completion: The completion to send.
    func sendOnMain(completion: Subscribers.Completion<Failure>) {
        DispatchQueue.main.async {
            self.send(completion: completion)
        }
    }
}
