//
//  ActivityViewController.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 15.07.2023.
//

import SwiftUI
import LinkPresentation

/// A view controller that presents a share sheet with various activities.
struct ActivityViewController: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIActivityViewController

    /// The items to be shared in the activity view controller.
    let activityItems: [Any]
    
    /// A completion handler that is called when the user completes an activity.
    let completion: UIActivityViewController.CompletionWithItemsHandler?
    
    /// Creates and configures the activity view controller.
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    
        activityViewController.completionWithItemsHandler = completion

        activityViewController.excludedActivityTypes = [
            .print,
            .addToReadingList,
            .assignToContact
        ]
        
        return activityViewController
    }
    
    /// Updates the activity view controller.
    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) { }
}

/// An item used as a data source for the activity view controller.
class ItemDetailSource: NSObject {
    /// The name of the item.
    let name: String
    
    /// The image of the item.
    let image: UIImage

    /// Creates an item with the specified name and image.
    init(name: String, image: UIImage) {
        self.name = name
        self.image = image
    }
}

extension ItemDetailSource: UIActivityItemSource {
    /// Returns the placeholder item for the activity view controller.
    func activityViewControllerPlaceholderItem(
        _ activityViewController: UIActivityViewController
    ) -> Any {
        image
    }
    
    /// Returns the item to be shared for the specified activity type.
    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        image
    }

    /// Returns link metadata for the activity view controller.
    func activityViewControllerLinkMetadata(
        _ activityViewController: UIActivityViewController
    ) -> LPLinkMetadata? {
        let metaData = LPLinkMetadata()
        metaData.title = name
        metaData.imageProvider = NSItemProvider(object: image)
        return metaData
    }
}
