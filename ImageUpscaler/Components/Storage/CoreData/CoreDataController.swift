//
//  CoreDataController.swift
//  ImageUpscaler
//
//  Created by Vsevolod Pavlovskyi on 16.06.2023.
//

import CoreData

struct CoreDataController {
    static let shared = CoreDataController()
    
    private let container: NSPersistentContainer

    private var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    init(isInMemory: Bool = false) {
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
    func fetchImages() throws -> [ImageInfo] {
        let request = ImageData.fetchRequest()
        let results = try viewContext.fetch(request)
        
        return results.compactMap { result in
            guard
                let id = result.id,
                let data = result.data
            else {
                return nil
            }
            
            return ImageInfo(id: id, data: data)
        }
    }
    
    func addImages(_ imageInfos: [ImageInfo]) throws {
        imageInfos.forEach { info in
            let container = ImageData(context: viewContext)

            container.id = info.id
            container.data = info.data
        }
        
        try viewContext.save()
    }
    
    func deleteImages(_ imageInfos: [ImageInfo]) throws {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ImageData")
        request.predicate = NSPredicate(format: "id IN %@", imageInfos.map(\.id))
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        try viewContext.execute(batchDeleteRequest)
        try viewContext.save()
    }
}
