//
//  ImageUpscalerTests.swift
//  ImageUpscalerTests
//
//  Created by Vsevolod Pavlovskyi on 16.06.2023.
//

import XCTest
@testable import ImageUpscaler

final class ImageUpscalerTests: XCTestCase {
    func testReadWriteImages() throws {
        let storage = CoreDataController(isInMemory: true)
        
        // This method operates Data, so no need for image save to test functionality.
        let someData = "Some data".data(using: .utf8)!
        try storage.addImages([someData])
        
        let datas = try storage.fetchImages()
        
        XCTAssertEqual(someData, datas.first ?? nil)
    }
}
