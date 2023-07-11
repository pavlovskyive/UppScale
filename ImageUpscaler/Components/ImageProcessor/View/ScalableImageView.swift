//
//  ScalableImageView.swift
//  
//
//  Created by Vsevolod Pavlovskyi on 25.06.2023.
//

import SwiftUI

struct ScalableImageView: View {
    @State private var scale = 1.0
    @State private var lastScale = 0.0
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    
    @GestureState private var isInteracting = false
    
    private let image: Image
    
    init(image: Image) {
        self.image = image
    }
    
    var body: some View {
        imageView
    }
}

private extension ScalableImageView {
    var imageView: some View {
        GeometryReader { proxy in
            let size = proxy.size
            
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .overlay(
                    GeometryReader { proxy in
                        let rect = proxy.frame(in: CoordinateSpace.named("IMAGEVIEW"))
                        
                        Color.clear
                            .onChange(of: isInteracting) { isInteracting in
                                guard !isInteracting else {
                                    return
                                }
                                
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if rect.minX > 0 {
                                        if rect.width > size.width {
                                            offset.width -= rect.minX
                                        } else {
                                            offset.width = 0
                                        }
  
                                        haptics(style: .light)
                                    }
                                    
                                    if rect.maxX < size.width {
                                        if rect.height > size.height {
                                            offset.width = rect.minX - offset.width
                                        } else {
                                            offset.width = 0
                                        }

                                        haptics(style: .light)
                                    }
                                    
                                    if rect.minY > 0 {
                                        if rect.height > size.height {
                                            offset.height -= rect.minY
                                        } else {
                                            offset.height = 0
                                        }

                                        haptics(style: .light)
                                    }
                                    
                                    if rect.maxY < size.height {
                                        if rect.height > size.height {
                                            offset.height = rect.minY - offset.height
                                        } else {
                                            offset.height = 0
                                        }

                                        haptics(style: .light)
                                    }
                                }
                                
                                lastOffset = offset
                            }
                    }
                )
                .frame(size: size)
        }
        .scaleEffect(scale)
        .offset(offset)
        .coordinateSpace(name: "IMAGEVIEW")
        .gesture(
            DragGesture()
                .updating($isInteracting) { _, out, _ in
                    out = true
                }
                .onChanged { value in
                    let translation = value.translation
                    offset = translation + lastOffset
                }
        )
        .gesture(
            MagnificationGesture()
                .updating($isInteracting) { _, out, _ in
                    out = true
                }
                .onChanged { value in
                    let updatedValue = value * (lastScale + 1)

                    let newScale = min(max(1, updatedValue), 4)
                    
                    guard newScale != scale else {
                        return
                    }
                    
                    scale = newScale
                    
                    if scale == 1 || scale == 4 {
                        haptics(style: .light)
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if scale <= 1 {
                            scale = 1
                            lastScale = 0
                        } else {
                            lastScale = scale - 1
                        }
                    }
                }
        )
    }
}

private extension View {
    func frame(size: CGSize) -> some View {
        frame(width: size.width, height: size.height)
    }
    
    func haptics(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

private extension CGSize {
    static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(
            width: lhs.width + rhs.width,
            height: lhs.height + rhs.height
        )
    }
}
