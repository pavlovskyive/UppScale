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
}

extension ProcessingType {
    var title: String {
        switch self {
        case .upscaling:
            return "Upscale your image"
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
    @State private var selection: PhotosPickerItem?
    @State private var path = NavigationPath()
    @State private var processingType = ProcessingType.upscaling
    @State private var photosPickerPresented = false
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    imagePicker(for: .upscaling)
                    imagePicker(for: .lightEnhancing)
                }
                .padding(.horizontal, 16)
            }
            .background(.background)
            .photosPicker(
                isPresented: $photosPickerPresented,
                selection: $selection,
                matching: .all(of: [.images]),
                photoLibrary: .shared()
            )
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
                        let info = ImageInfoSpec(image: image)
                        path.append(info)
                    }
                }
            }
            .navigationDestination(for: ImageInfoSpec.self) { info in
                switch processingType.method {
                case .imageToImage:
                    ImageToImageProcessingView(
                        processingType: processingType,
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
    func imagePicker(for method: ProcessingType) -> some View {
        ProcessingInfoCard(processingType: method)
            .onTapGesture {
                processingType = method
                photosPickerPresented.toggle()
            }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MainView()
        }
    }
}
