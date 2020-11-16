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

        return fetchedResultsController
    }()
    
    func fetchFresh(completionHandler: @escaping (Error?) -> Void) {
        _ = service.fetchTopPosts(limit: 50, offset: 0) { (error) in
            completionHandler(error)
        }
    }
    
    func downloadThumbnail(at indexPath: IndexPath) {
        
    }
    
    init(service: ListingService) {
        self.service = service
    }
}
