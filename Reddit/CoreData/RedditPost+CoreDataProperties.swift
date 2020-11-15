//
//  RedditPost+CoreDataProperties.swift
//  Reddit
//
//  Created by Alexey Kolyadenko on 15.11.2020.
//
//

import Foundation
import CoreData


extension RedditPost {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RedditPost> {
        return NSFetchRequest<RedditPost>(entityName: "RedditPost")
    }

    @NSManaged public var authorFullname: String?
    @NSManaged public var comments: Int64
    @NSManaged public var created: Date?
    @NSManaged public var id: String?
    @NSManaged public var subreddit: String?
    @NSManaged public var thumbnail: URL?
    @NSManaged public var title: String?

}

extension RedditPost : Identifiable {

}
