//
//  CoreDataControllerTests.swift
//  ImageUpscalerTests
//
//  Created by Vsevolod Pavlovskyi on 16.06.2023.
//

import XCTest
@testable import ImageUpscaler

// swiftlint:disable force_unwrapping
final class CoreDataControllerTests: XCTestCase {
    func testReadWriteImages() throws {
        let storage = CoreDataController(isInMemory: true)
        
        let initialInfos = ["1", "2"]
            .compactMap { $0.data(using: .utf8) }
            .map { ImageInfo(data: $0) }
            .sorted { $0.id.uuidString > $1.id.uuidString }
        
        try storage.addImages(initialInfos)
        
        let result = try storage.fetchImages().sorted { $0.id.uuidString > $1.id.uuidString }
        
        XCTAssertEqual(result, initialInfos)
    }
    
    func testDelete() throws {
        let storage = CoreDataController(isInMemory: true)
        
        let initialInfos = ["1", "2"]
            .compactMap { $0.data(using: .utf8) }
            .map { ImageInfo(data: $0) }
        
        try storage.addImages(initialInfos)
        try storage.deleteImages([initialInfos.first!])
        
        let result = try storage.fetchImages()
        
        XCTAssertEqual(result, [initialInfos.last!])
    }
}
// swiftlint:enable force_unwrapping
