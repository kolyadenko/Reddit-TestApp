//
//  ListingService.swift
//  Reddit
//
//  Created by Alexey Kolyadenko on 16.11.2020.
//

import Foundation
import CoreData

// MARK: Protocols
protocol ListingService {
    typealias ListingFetchCompletionHandler = (Error?) -> Void
    
    func fetchTopPosts(count: Int?, completionHandler: @escaping ListingFetchCompletionHandler) -> Cancellable?
    func observeListingChanges(with block: @escaping NoArgumentsVoidBlock)
    var coreDataManager: CoreDataManager { get }
}

protocol Cancellable {
    func cancel()
}

// MARK: Model
struct Listing: Decodable {
    var data: ListingData

    struct ListingData: Decodable {
        var children: [Post]
        var after: String?
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
