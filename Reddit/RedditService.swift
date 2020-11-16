//
//  RedditService.swift
//  Reddit
//
//  Created by Alexey Kolyadenko on 09.11.2020.
//

import Foundation
import CoreData

// MARK: Protocols
protocol ListingService {
    typealias ListingFetchCompletionHandler = (Listing?, Error?) -> Void

    func fetchTopPosts(limit: Int, offset: Int, completionHandler: @escaping ListingFetchCompletionHandler) -> Cancellable?
}

protocol Cancellable {
    func cancel()
}

// MARK: Model
struct Listing: Decodable {
    var data: ListingData

    struct ListingData: Decodable {
        var children: [Post]
    }
}

struct Post: Decodable {
    var data: PostData
    
    struct PostData: Decodable {
        var id: String
        var authorFullname: String
        var subreddit: String?
        var title: String
        var thumbnail: URL?
        var created: Date
        var comments: Int
        
        enum CodingKeys: String, CodingKey {
            case authorFullname = "author_fullname"
            case subreddit, title, thumbnail, created, id
            case comments = "num_comments"
        }
    }
}

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
    
    func fetchTopPosts(limit: Int = 50, offset: Int, completionHandler: @escaping ListingFetchCompletionHandler) -> Cancellable? {
        guard let url = URL(string: topListingURL) else { return nil }
        let request = URLRequest(url: url)
        let dataTask = session.dataTask(with: request) { [unowned self] (data, response, error) in
            guard let data = data else {
                completionHandler(nil, error)
                return
            }
            let listing = try? self.decoder.decode(Listing.self, from: data)
            let backgroundContext = persistentContainer.newBackgroundContext()
            listing?.data.children.forEach({
                self.configure(redditPost: RedditPost(context: persistentContainer.viewContext), usingPost: $0, context: backgroundContext)
            })
            saveContext(context: backgroundContext)
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

    // MARK: - Core Data Saving support
    func saveContext(context: NSManagedObjectContext?) {
        let context = context ?? persistentContainer.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        if context.hasChanges {
            context.perform {
                do {
                    try context.save()
                } catch {
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
    }
}

extension URLSessionDataTask: Cancellable {}
