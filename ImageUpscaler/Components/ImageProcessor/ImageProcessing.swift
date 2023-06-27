//
//  ImageProcessing.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 23.06.2023.
//

import SwiftUI

protocol ImageProcessing {
    associatedtype Parameters

    init() throws
    func processImage(parameters: Parameters) async throws -> UIImage
}
