//
//  ImagesStorageProvider.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 16.06.2023.
//

import Foundation

public protocol ImagesStorageProvider {
    func fetchImages() throws -> [Data]
    func addImages(_ imagesData: [Data]) throws
}
