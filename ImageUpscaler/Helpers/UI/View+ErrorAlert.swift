//
//  View+ErrorAlert.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 14.07.2023.
//

import SwiftUI

/// A convenient extension for displaying an alert for an error.
extension View {
    /// Presents an alert for the specified error.
    ///
    /// - Parameters:
    ///   - error: A binding to an `Error` value representing the error to display.
    ///   - buttonTitle: The title of the button that dismisses the alert. The default value is "OK".
    /// - Returns: A view that presents an alert for the specified error.
    func errorAlert(
        error: Binding<Error?>,
        buttonTitle: String = "button.ok".localized
    ) -> some View {
        // Create a LocalizedAlertError based on the wrapped value of the error binding.
        let localizedAlertError = LocalizedAlertError(error: error.wrappedValue)
        
        // Create an alert view with the error information.
        let alert = alert(
            isPresented: .constant(localizedAlertError != nil),
            error: localizedAlertError,
            actions: { _ in
                // Add a button to dismiss the alert and clear the error binding.
                Button(buttonTitle) {
                    error.wrappedValue = nil
                }
            },
            message: { error in
                // Display the recovery suggestion text from the error, if available.
                Text(error.recoverySuggestion ?? "")
            }
        )
        
        // Return the alert view.
        return alert
    }
}

/// A wrapper for a localized error conforming to the `LocalizedError` protocol.
struct LocalizedAlertError: LocalizedError {
    let underlyingError: LocalizedError
    
    /// A localized message describing the error.
    var errorDescription: String? {
        underlyingError.errorDescription
    }
    
    /// A localized message describing how to recover from the error.
    var recoverySuggestion: String? {
        underlyingError.recoverySuggestion
    }

    /// Creates a `LocalizedAlertError` by wrapping the specified error.
    ///
    /// - Parameter error: The error to be wrapped.
    /// - Returns: A `LocalizedAlertError` instance wrapping the specified error, or `nil` if the error does not conform to `LocalizedError`.
    init?(error: Error?) {
        // Try to cast the error to a LocalizedError and assign it to the underlyingError property.
        guard let localizedError = error as? LocalizedError else {
            return nil
        }
        
        underlyingError = localizedError
    }
}
