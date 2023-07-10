//
//  MainView.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 17.06.2023.
//

import SwiftUI
import PhotosUI

//extension CGFloat {
//    static let xxxSmall = 2.0
//    static let xxSmall = 4.0
//    static let xSmall = 8.0
//    static let small = 16.0
//    static let medium = 24.0
//    static let large = 32.0
//    static let xLarge = 48.0
//    static let xxLarge = 52.0
//    static let xxxLarge = 64.0
//}

private struct ImageInfoSpec: Hashable {
    let id = UUID()
    let image: UIImage
    let processingMethod: ImageProcessingMethod
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
                imagePicker(for: .upscaling)
                
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
                imageSystemName: "camera.on.rectangle.fill",
                title: "Upscale your image",
                subtitle: "Select an image to upscale"
            )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    print("-> selected new method")
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
