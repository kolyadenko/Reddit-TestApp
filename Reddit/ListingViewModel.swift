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
    // MARK: Init
    init(service: ListingService) {
        self.service = service
    }
    
    // MARK: Props
    var service: ListingService
    let imageCache = NSCache<NSString, UIImage>()
    let formatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter
    }()
    
    lazy var listingFetchedResultsController: NSFetchedResultsController<RedditPost> = {
        let fetchRequest: NSFetchRequest<RedditPost> = RedditPost.fetchRequest()

        let sortDescriptor = NSSortDescriptor(key: "created", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.service.coreDataManager.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }()
    
    // MARK: Public API
    func downloadImage(at indexPath: IndexPath, completionHandler: @escaping NoArgumentsVoidBlock) {
        let item = listingFetchedResultsController.object(at: indexPath)
        guard let url = item.thumbnail else { return }
        downloadThumbnail(at: url) { (_) in
            completionHandler()
        }
    }
    
    func cancelImageDownloading(at indexPath: IndexPath) {
        let item = listingFetchedResultsController.object(at: indexPath)
        guard let url = item.thumbnail else { return }
        cancelThumbnailDownloading(at: url)
    }
    
    func item(at indexPath: IndexPath) -> RedditPostTableViewCell.Model {
        let item = listingFetchedResultsController.object(at: indexPath)
        let thumbURL = item.thumbnail
        let image = thumbURL == nil ? nil : self.image(at: thumbURL!)
        let postedBy = "\(item.author ?? "") - \(relativeDate(at: indexPath))"
        return RedditPostTableViewCell.Model(postedBy: postedBy, name: item.title ?? "", commentsTitle: "\(item.comments) Comments", image: image, shouldLoadImage: image == nil && item.thumbnail != nil)
    }
    
    func fetchData(offset: Int, completionHandler: @escaping (Error?) -> Void) {
        let taskKey = offset
        fetchTasks[taskKey]?.cancel()
        fetchTasks[taskKey] = service.fetchTopPosts(count: taskKey, completionHandler: { [unowned self] (error) in
            completionHandler(error)
            self.fetchTasks[taskKey] = nil
        })
    }
    
    // MARK: Private
    private var thumbnailDownloadTasks: [String: Cancellable] = [:]
    private var fetchTasks: [Int: Cancellable] = [:]

    private func downloadThumbnail(at url: URL, completionHandler: @escaping (UIImage?) -> Void) {
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
    
    private func image(at url: URL) -> UIImage? {
        return imageCache.object(forKey: url.absoluteString as NSString)
    }
    
    private func relativeDate(at indexPath: IndexPath) -> String {
        let date = listingFetchedResultsController.object(at: indexPath).created
        let relativeDate = formatter.localizedString(for: Date(), relativeTo: date ?? Date())
        return relativeDate
    }
    
    private func cancelThumbnailDownloading(at url: URL) {
        thumbnailDownloadTasks[url.absoluteString]?.cancel()
    }
}
