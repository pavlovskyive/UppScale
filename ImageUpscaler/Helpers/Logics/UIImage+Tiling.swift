//
//  UIImage+Tiling.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 13.07.2023.
//

import UIKit

struct Tile {
    let image: CGImage
    let rect: CGRect
}

extension UIImage {
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
                rect: CGRect(
                    x: 0, y: 0,
                    width: width,
                    height: height
                )
            )
            
            return [singleTile]
        }

        let overlapSize = Int(Double(tileSize) * overlap)
        
        var tiles = [Tile]()
        
        for y in stride(from: 0, to: height, by: tileSize - overlapSize) {
            for x in stride(from: 0, to: width, by: tileSize - overlapSize) {
                let finalX = min(x, width - tileSize)
                let finalY = min(y, height - tileSize)
                
                let tileRect = CGRect(x: finalX, y: finalY, width: tileSize, height: tileSize)
                
                guard let image = cgImage.cropping(to: tileRect) else {
                    return nil
                }

                let tile = Tile(
                    image: image,
                    rect: tileRect
                )
                
                tiles.append(tile)
            }
        }
        
        return tiles
    }

    func withPlaced(tile: Tile) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let newImage = renderer.image { context in
            context.cgContext.interpolationQuality = .high
            context.cgContext.setShouldAntialias(true)

            draw(in: CGRect(origin: .zero, size: size))
            context.cgContext.draw(tile.image, in: tile.rect)
        }

        return newImage
    }
}
