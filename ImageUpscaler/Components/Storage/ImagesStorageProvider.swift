//
//  ImagesStorageProvider.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 16.06.2023.
//

import Foundation

protocol ImagesStorageProvider {
    func fetchImages() throws -> [ImageInfo]
    func addImages(_ imagesInfos: [ImageInfo]) throws
    func deleteImages(_ imageInfos: [ImageInfo]) throws
}
