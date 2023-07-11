//
//  MainView.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 17.06.2023.
//

import SwiftUI
import PhotosUI

private struct ImageInfoSpec: Hashable {
    let id = UUID()
    let image: UIImage
    let processingMethod: ImageProcessingMethod
}

enum ImageProcessingMethod {
    case upscaling
    case lightEnhancing
    
    var title: String {
        switch self {
        case .upscaling:
            return "Upscale you image"
        case .lightEnhancing:
            return "Enhance light"
        }
    }
    
    var subtitle: String {
        switch self {
        case .upscaling:
            return "Select image to improve its resolution"
        case .lightEnhancing:
            return "Bring light to very dark images"
        }
    }
    
    var systemImage: String {
        switch self {
        case .upscaling:
            return "arrow.up.backward.and.arrow.down.forward"
        case .lightEnhancing:
            return "flashlight.on.fill"
        }
    }
}

struct MainView: View {
    @EnvironmentObject var imageProcessorsManager: ImageProcessorsManager

    @State private var selection: PhotosPickerItem?
    @State private var path = NavigationPath()
    @State private var selectedMethod = ImageProcessingMethod.upscaling
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                Spacer()
                
                imagePicker(for: .upscaling)
                imagePicker(for: .lightEnhancing)
                
                Spacer()
            }
            .background(backgroundImage)
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    infoButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    settingsButton
                }
            }
            .materialNavigation()
            .navigationTitle("AppScale")
            .onChange(of: selection) { selectedItem in
                Task {
                    guard
                        let data = try? await selectedItem?.loadTransferable(type: Data.self),
                        let image = UIImage(data: data)
                    else {
                        print("Failed")
                        
                        return
                    }
                    
                    await MainActor.run {
                        let info = ImageInfoSpec(image: image, processingMethod: selectedMethod)
                        path.append(info)
                    }
                }
            }
            .navigationDestination(for: ImageInfoSpec.self) { info in
                switch info.processingMethod {
                case .upscaling:
                    let processor = imageProcessorsManager.getProcessor(
                        for: UpscalingProcessor.self
                    ) {
                        UpscalingProcessor()
                    }
                    
                    ImageToImageProcessingView(
                        processor: processor,
                        uiImage: info.image
                    )
                case .lightEnhancing:
                    let upscalingProcessor = imageProcessorsManager.getProcessor(
                        for: UpscalingProcessor.self
                    ) {
                        UpscalingProcessor()
                    }
                    
                    let processor = imageProcessorsManager.getProcessor(
                        for: LightEnhancingProcessor.self
                    ) {
                        LightEnhancingProcessor(upscalingProcessor: upscalingProcessor)
                    }
                    
                    ImageToImageProcessingView(
                        processor: processor,
                        postProcessor: upscalingProcessor,
                        uiImage: info.image
                    )
                }
            }
        }
    }
}

private extension MainView {
    var backgroundImage: some View {
        Image("background-abstract") // https://app.haikei.app
            .resizable()
            .scaledToFill()
            .edgesIgnoringSafeArea(.all)
        //            .overlay(.ultraThinMaterial)
    }
    var infoButton: some View {
        Button {
            print("info")
        } label: {
            Image(systemName: "info.circle")
        }
        .buttonStyle(.plain)
    }
    
    var settingsButton: some View {
        Button {
            print("settings")
        } label: {
            Image(systemName: "gearshape")
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    func imagePicker(for method: ImageProcessingMethod) -> some View {
        PhotosPicker(
            selection: $selection,
            matching: .all(of: [.images, .not(.screenshots)]),
            photoLibrary: .shared()
        ) {
            InfoBlockView(
                imageSystemName: method.systemImage,
                title: method.title,
                subtitle: method.subtitle
            )
            .frame(width: 250)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    selectedMethod = method
                }
        )
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MainView()
        }
    }
}
