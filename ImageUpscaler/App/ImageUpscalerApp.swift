//
//  ImageUpscalerApp.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 13.06.2023.
//

import SwiftUI

@main
struct ImageUpscalerApp: App {
    @ObservedObject var imageProcessorsManager = ImageProcessorsManager()
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(imageProcessorsManager)
        }
    }
}
