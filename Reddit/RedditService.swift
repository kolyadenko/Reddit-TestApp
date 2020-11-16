//
//  RedditService.swift
//  Reddit
//
//  Created by Alexey Kolyadenko on 09.11.2020.
//

import Foundation
import CoreData

// MARK: Implementation
class RedditService: ListingService {
    // MARK: Init
    private var observers: [NSObjectProtocol] = []
    init() {
        observers.append(notificationCenter.addObserver(forName: NSNotification.Name.NSManagedObjectContextDidSave, object: nil, queue: nil) { (notification) in
            self.listingChangesBlock?()
        })
    }
    
    deinit {
        observers.forEach({ notificationCenter.removeObserver($0) })
    }
    
    // MARK: Props
    private let topListingURL = "https://www.reddit.com/top.json"
    private var session: URLSession = .shared
    var coreDataManager: CoreDataManager = .init()
    let notificationCenter = NotificationCenter.default
    private var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateDouble = try container.decode(Double.self)
            let date = Date(timeIntervalSince1970: dateDouble)
            return date
        })
        return decoder
    }()
    
    // MARK: Implementation
    func fetchTopPosts(limit: Int, before: String?, completionHandler: @escaping ListingFetchCompletionHandler) -> Cancellable? {
        let destinationURLString = before == nil ? topListingURL : "\(topListingURL)?before=t3_\(before!)"
        guard let url = URL(string: destinationURLString) else { return nil }
        print(url)
        let request = URLRequest(url: url)
        let dataTask = session.dataTask(with: request) { [unowned self] (data, response, error) in
            guard let data = data else {
                completionHandler(error)
                return
            }
            let listing = try? self.decoder.decode(Listing.self, from: data)
            let backgroundContext = coreDataManager.persistentContainer.newBackgroundContext()
            listing?.data.children.forEach({
                self.configure(redditPost: RedditPost(context: backgroundContext), usingPost: $0, context: backgroundContext)
            })
            print(listing)
            coreDataManager.saveContext(context: backgroundContext)
            DispatchQueue.main.async {
                completionHandler(error)
            }
        }
        dataTask.resume()
        return dataTask
    }
    
    private var listingChangesBlock: NoArgumentsVoidBlock?
    func observeListingChanges(with block: @escaping NoArgumentsVoidBlock) {
        self.listingChangesBlock = block
    }
    
    // MARK: Private funcs
    private func configure(redditPost: RedditPost, usingPost post: Post, context: NSManagedObjectContext) {
        let postData = post.data
        redditPost.id = postData.id
        redditPost.authorFullname = postData.authorFullname
        redditPost.comments = Int64(postData.comments)
        redditPost.created = postData.created
        redditPost.subreddit = postData.subreddit
        redditPost.thumbnail = postData.thumbnail
        redditPost.title = postData.title
    }
}

extension URLSessionDataTask: Cancellable {}
