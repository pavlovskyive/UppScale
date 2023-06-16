//
//  ImageInfo.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 16.06.2023.
//

import Foundation

struct ImageInfo {
    let id: UUID
    let data: Data
    
    init(id: UUID = UUID(), data: Data) {
        self.id = id
        self.data = data
    }
}

extension ImageInfo: Equatable {
    static func ==(lhs: ImageInfo, rhs: ImageInfo) -> Bool {
        lhs.id == rhs.id && lhs.data == rhs.data
    }
}
