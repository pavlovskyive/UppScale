//
//  String+Localized.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 15.07.2023.
//

import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}
