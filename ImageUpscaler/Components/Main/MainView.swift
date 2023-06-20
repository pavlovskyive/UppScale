//
//  MainView.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 17.06.2023.
//

import SwiftUI
import PhotosUI

extension CGFloat {
    static let xxxSmall = 2.0
    static let xxSmall = 4.0
    static let xSmall = 8.0
    static let small = 16.0
    static let medium = 24.0
    static let large = 32.0
    static let xLarge = 48.0
    static let xxLarge = 52.0
    static let xxxLarge = 64.0
}

private struct ImageInfoSpec: Hashable {
    let id = UUID()
    let data: Data
}

struct MainView: View {
    @State private var selection: PhotosPickerItem?
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                Spacer()
                
                imagePicker
                
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
            
            .navigationDestination(for: ImageInfoSpec.self) { info in
                ImageDetailView(imageData: info.data)
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
    
    var imagePicker: some View {
        PhotosPicker(
            selection: $selection,
            matching: .all(of: [.images, .not(.screenshots)]),
            photoLibrary: .shared()
        ) {
            InfoBlockView(
                imageSystemName: "camera.on.rectangle.fill",
                title: "Choose Photo",
                subtitle: "And enhance it right away"
            )
        }
        .buttonStyle(.plain)
        .onChange(of: selection) { selectedItem in
            Task {
                guard let data = try? await selectedItem?.loadTransferable(type: Data.self) else {
                    print("Failed")
                    
                    return
                }
                
                let info = ImageInfoSpec(data: data)
                path.append(info)
            }
        }
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
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MainView()
        }
    }
}
