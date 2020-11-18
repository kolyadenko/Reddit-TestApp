//
//  CoreDataManager.swift
//  Reddit
//
//  Created by Alexey Kolyadenko on 16.11.2020.
//

import Foundation
import CoreData

class CoreDataManager {
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()
    
    lazy var backgroundContext: NSManagedObjectContext = {
        return persistentContainer.newBackgroundContext()
    }()

    // MARK: - Core Data Saving support
    func saveContext(context: NSManagedObjectContext?, completionHandler: NoArgumentsVoidBlock?) {
        let context = context ?? persistentContainer.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        if context.hasChanges {
            context.perform {
                do {
                    try context.save()
                    completionHandler?()
                } catch {
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
    }
}
