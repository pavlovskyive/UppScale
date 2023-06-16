//
//  View+ErrorAlert.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 16.06.2023.
//

import SwiftUI

private struct LocalizedAlertError: LocalizedError {
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

extension View {
    func errorAlert(
        error: Binding<Error?>,
        buttonTitle: String = "Ok"
    ) -> some View {
        let localizedAlertError = LocalizedAlertError(error: error.wrappedValue)
        
        return alert(
            isPresented: .constant(localizedAlertError != nil),
            error: localizedAlertError
        ) { _ in
            Button(buttonTitle) {
                error.wrappedValue = nil
            }
        } message: { error in
            Text(error.recoverySuggestion ?? "")
        }
    }
}
