//
//  ViewController.swift
//  Reddit
//
//  Created by Alexey Kolyadenko on 09.11.2020.
//

import UIKit
import CoreData

class ListingViewController: UIViewController {
    var items: [Post.PostData] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    let service: RedditService = .init()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        service.fetchTopPosts(offset: 0, completionHandler: { listing, error in
            self.items = listing?.data.children.compactMap({ $0.data }) ?? []
        })
    }
}

class ListingViewModel {
    var service: ListingService
    
//    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<RedditPost> = {
//        // Initialize Fetch Request
//        let fetchRequest: NSFetchRequest<RedditPost> = Note.fetchRequest()
//
//        // Add Sort Descriptors
//        let sortDescriptor = NSSortDescriptor(key: "created", ascending: true)
//        fetchRequest.sortDescriptors = [sortDescriptor]
//
//        // Initialize Fetched Results Controller
//        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.coreDataManager.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
//
//        return fetchedResultsController
//    }()
    
    init(service: ListingService) {
        self.service = service
    }
}

extension ListingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "RedditPostTableViewCell", for: indexPath) as! RedditPostTableViewCell
        cell.postedByTitle.text = item.authorFullname
        cell.nameLabel.text = item.title
        cell.commentsLabel.text = "\(item.comments) Comments"
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

class RedditPostTableViewCell: UITableViewCell {
    @IBOutlet weak var postedByTitle: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var commentsLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
}
