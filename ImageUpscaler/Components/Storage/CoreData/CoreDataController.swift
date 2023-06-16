//
//  CoreDataController.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 16.06.2023.
//

import CoreData

public struct CoreDataController {
    static let shared = CoreDataController()
    
    private let container: NSPersistentContainer

    private var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    public init(isInMemory: Bool = false) {
        container = NSPersistentContainer(name: "CoreDataModel")
        
        if isInMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as? NSError {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        viewContext.automaticallyMergesChangesFromParent = true
    }
}

extension CoreDataController: ImagesStorageProvider {
    public func fetchImages() throws -> [Data] {
        let request = NSFetchRequest<ImageData>(entityName: "ImageData")
        let response = try viewContext.fetch(request)
        
        return response.compactMap(\.data)
    }
    
    public func addImages(_ imagesData: [Data]) throws {
        imagesData.forEach { data in
            let container = ImageData(context: viewContext)
            container.data = data
        }
        
        try viewContext.save()
    }
}
