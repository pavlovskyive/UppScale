//
//  ContentView.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 13.06.2023.
//

import PhotosUI
import SwiftUI

struct ContentView: View {
    let storage = CoreDataController()
    
    var body: some View {
        NavigationStack {
            ImagesView(storage: storage)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
