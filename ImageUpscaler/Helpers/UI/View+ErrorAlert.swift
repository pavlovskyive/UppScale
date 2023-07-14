//
//  View+ErrorAlert.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 14.07.2023.
//

import SwiftUI

extension View {
    func errorAlert(error: Binding<Error?>, buttonTitle: String = "OK") -> some View {
        let localizedAlertError = LocalizedAlertError(error: error.wrappedValue)
        let alert = alert(
            isPresented: .constant(localizedAlertError != nil),
            error: localizedAlertError,
            actions: { _ in
                Button(buttonTitle) {
                    error.wrappedValue = nil
                }
            },
            message: { error in
                Text(error.recoverySuggestion ?? "")
            }
        )

        return alert
    }
}

struct LocalizedAlertError: LocalizedError {
    let underlyingError: LocalizedError
    var errorDescription: String? {
        underlyingError.errorDescription
    }
    var recoverySuggestion: String? {
        underlyingError.recoverySuggestion
    }

    init?(error: Error?) {
        guard let localizedError = error as? LocalizedError else {
            return nil
        }

        underlyingError = localizedError
    }
}
