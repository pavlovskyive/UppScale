//
//  UIImage+Tiling.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 13.07.2023.
//

import UIKit

import SwiftUI
import LinkPresentation

/// Represents a tile with an image and its corresponding rectangle.
struct Tile {
    /// The image of the tile.
    let image: CGImage
    
    /// The rectangle defining the position and size of the tile.
    let rect: CGRect
}

extension UIImage {
    /// Splits the image into multiple tiles.
    /// - Parameters:
    ///   - maxTileCount: The maximum number of tiles to generate. Default is 20.
    ///   - overlap: The overlap ratio between tiles. Default is 1/4.
    ///   - tileSize: The size of each tile. This value is modified to be within the bounds of the image. Returns the adjusted tileSize.
    /// - Returns: An array of tiles or `nil` if the image cannot be split.
    func tiles(
        maxTileCount: Int = 20,
        overlap: CGFloat = 1 / 4,
        tileSize: inout Int
    ) -> [Tile]? {
        guard let cgImage = self.cgImage else {
            return nil
        }
        
        let width = Int(cgImage.width)
        let height = Int(cgImage.height)
        
        tileSize = min(tileSize, width, height)
        
        if width == tileSize && height == tileSize {
            let singleTile = Tile(
                image: cgImage,
                rect: CGRect(x: 0, y: 0, width: width, height: height)
            )
            
            return [singleTile]
        }

        let overlapSize = Int(Double(tileSize) * overlap)
        
        var tiles = [Tile]()
        
        for y in stride(from: 0, to: height - overlapSize, by: tileSize - overlapSize) {
            for x in stride(from: 0, to: width - overlapSize, by: tileSize - overlapSize) {
                let finalX = min(x, width - tileSize)
                let finalY = min(y, height - tileSize)
                
                let tileRect = CGRect(x: finalX, y: finalY, width: tileSize, height: tileSize)
                
                guard let image = cgImage.cropping(to: tileRect) else {
                    return nil
                }

                let tile = Tile(image: image, rect: tileRect)
                
                tiles.append(tile)
            }
        }
        
        return tiles
    }

    /// Creates a new image by placing the specified tile on top of the receiver image.
    /// - Parameter tile: The tile to be placed on the image.
    /// - Returns: A new image with the tile placed on top.
    func withPlaced(tile: Tile) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size, format: .init(for: traitCollection))
        
        let newImage = renderer.image { context in
            context.cgContext.interpolationQuality = .high
            context.cgContext.setShouldAntialias(true)

            draw(in: CGRect(origin: .zero, size: size))
            context.cgContext.draw(tile.image, in: tile.rect)
        }

        return newImage
    }
}
