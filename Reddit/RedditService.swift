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
    private let topListingURL = "https://www.reddit.com/top.json"

    private var session: URLSession = .shared
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
    private var coreDataManager: CoreDataManager = .init()
    
    func fetchTopPosts(limit: Int = 50, offset: Int, completionHandler: @escaping ListingFetchCompletionHandler) -> Cancellable? {
        guard let url = URL(string: topListingURL) else { return nil }
        let request = URLRequest(url: url)
        let dataTask = session.dataTask(with: request) { [unowned self] (data, response, error) in
            guard let data = data else {
                completionHandler(nil, error)
                return
            }
            let listing = try? self.decoder.decode(Listing.self, from: data)
            let backgroundContext = coreDataManager.persistentContainer.newBackgroundContext()
            listing?.data.children.forEach({
                self.configure(redditPost: RedditPost(context: coreDataManager.persistentContainer.viewContext), usingPost: $0, context: backgroundContext)
            })
            coreDataManager.saveContext(context: backgroundContext)
            DispatchQueue.main.async {
                completionHandler(listing, error)
            }
        }
        dataTask.resume()
        return dataTask
    }
    
    private func configure(redditPost: RedditPost, usingPost post: Post, context: NSManagedObjectContext) {
        let postData = post.data
        let redditPost = RedditPost(context: context)
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
