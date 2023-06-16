//
//  ContentView.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 13.06.2023.
//

import PhotosUI
import SwiftUI

import Storage

struct ContentView: View {
    let storage: ImagesStorageProvider = CoreDataController()

    var body: some View {
        Text("Hello")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
