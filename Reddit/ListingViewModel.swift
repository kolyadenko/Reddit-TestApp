//
//  ListingViewModel.swift
//  Reddit
//
//  Created by Alexey Kolyadenko on 16.11.2020.
//

import Foundation
import CoreData

class ListingViewModel {
    var service: ListingService
    
    lazy var listingFetchedResultsController: NSFetchedResultsController<RedditPost> = {
        // Initialize Fetch Request
        let fetchRequest: NSFetchRequest<RedditPost> = RedditPost.fetchRequest()

        // Add Sort Descriptors
        let sortDescriptor = NSSortDescriptor(key: "created", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]

        // Initialize Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.service.coreDataManager.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        try? fetchedResultsController.performFetch()
        return fetchedResultsController
    }()

    func downloadThumbnail(at indexPath: IndexPath) {
        
    }
    
    var tasks: [String: Cancellable] = [:]
    
    func fetchData(offset: IndexPath?, completionHandler: @escaping (Error?) -> Void) {
        let beforeId = offset == nil ? nil : listingFetchedResultsController.object(at: offset!).id
        let taskKey = beforeId ?? "fresh"
        tasks[taskKey]?.cancel()
        tasks[taskKey] = service.fetchTopPosts(limit: 50, before: beforeId, completionHandler: { [unowned self] (error) in
            completionHandler(error)
            self.tasks[taskKey] = nil
        })
    }
    
    init(service: ListingService) {
        self.service = service
    }
}
