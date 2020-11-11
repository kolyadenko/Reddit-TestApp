//
//  RedditService.swift
//  Reddit
//
//  Created by Alexey Kolyadenko on 09.11.2020.
//

import Foundation

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
        var authorFullname: String
        var subreddit: String?
        var title: String?
        var thumbnail: URL?
        var created: Date?
        
        enum CodingKeys: String, CodingKey {
            case authorFullname = "author_fullname"
            case subreddit, title, thumbnail, created
        }
    }
}

// MARK: Implementation
enum CoercingError: Error {
    case failedToInit
}

extension KeyedDecodingContainer {
    func decodeCoercing<T: LosslessStringConvertible>(type: T.Type, forKey key: KeyedDecodingContainer.Key) throws -> T {
        guard let value = T(try self.decode(String.self, forKey: key)) else { throw CoercingError.failedToInit }
        return value
    }
}

extension SingleValueDecodingContainer {
    func decodeCoercing<T: LosslessStringConvertible>(type: T.Type) throws -> T {
        guard let value = T(try self.decode(String.self)) else { throw CoercingError.failedToInit }
        return value
    }
}

class RedditService: ListingService {
    private let topListingURL = "https://www.reddit.com/top.json"

    private var session: URLSession = .shared
    private var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateDouble = try container.decodeCoercing(type: Double.self)
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
            completionHandler(listing, error)
        }
        dataTask.resume()
        return dataTask
    }
}

extension URLSessionDataTask: Cancellable {}
