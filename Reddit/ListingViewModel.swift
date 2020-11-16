//
//  ListingViewModel.swift
//  Reddit
//
//  Created by Alexey Kolyadenko on 16.11.2020.
//

import Foundation
import CoreData
import UIKit

class ListingViewModel {
    var service: ListingService
    let imageCache = NSCache<NSString, UIImage>()
    
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
    
    private var thumbnailDownloadTasks: [String: Cancellable] = [:]
    func downloadThumbnail(at url: URL, completionHandler: @escaping (UIImage?) -> Void) {
        if let cachedImage = imageCache.object(forKey: url.absoluteString as NSString) {
            completionHandler(cachedImage)
        } else {
            thumbnailDownloadTasks[url.absoluteString] = service.downloadData(at: url) { [unowned self] (data, error) in
                if let data = data, let image = UIImage(data: data) {
                    imageCache.setObject(image, forKey: url.absoluteString as NSString)
                    DispatchQueue.main.async {
                        completionHandler(image)
                    }
                }
            }
        }
    }
    
    func image(at url: URL) -> UIImage? {
        return imageCache.object(forKey: url.absoluteString as NSString)
    }
    
    func cancelThumbnailDownloading(at url: URL) {
        thumbnailDownloadTasks[url.absoluteString]?.cancel()
    }
    
    var tasks: [Int: Cancellable] = [:]
    
    func fetchData(offset: Int, completionHandler: @escaping (Error?) -> Void) {
        let taskKey = offset
        tasks[taskKey]?.cancel()
        tasks[taskKey] = service.fetchTopPosts(count: taskKey, completionHandler: { [unowned self] (error) in
            completionHandler(error)
            self.tasks[taskKey] = nil
        })
    }
    
    init(service: ListingService) {
        self.service = service
    }
}
