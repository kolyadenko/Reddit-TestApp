//
//  ViewController.swift
//  Reddit
//
//  Created by Alexey Kolyadenko on 09.11.2020.
//

import UIKit
import CoreData

class ListingViewController: UIViewController, ErrorHandler {
    var items: [Post.PostData] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.refreshControl = UIRefreshControl()
            tableView.refreshControl?.addTarget(self, action: #selector(fetchFresh), for: .valueChanged)
        }
    }
    var viewModel = ListingViewModel(service: RedditService())

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchFresh()
    }
    
    @objc
    func fetchFresh() {
        viewModel.fetchFresh(completionHandler: { [unowned self] error in
            self.handle(error: error, retryBlock: { [unowned self] in self.fetchFresh() })
            performFetch()
        })
    }
    
    func performFetch() {
        do {
            try viewModel.listingFetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        self.tableView.refreshControl?.endRefreshing()
        self.tableView.reloadData()
    }
}

extension ListingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = viewModel.listingFetchedResultsController.sections else {
            return 0
        }

        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = viewModel.listingFetchedResultsController.object(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "RedditPostTableViewCell", for: indexPath) as! RedditPostTableViewCell
        cell.postedByTitle.text = item.authorFullname
        cell.nameLabel.text = item.title
        cell.commentsLabel.text = "\(item.comments) Comments"
        viewModel.downloadThumbnail(at: indexPath)
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

// MARK: Extensions
typealias NoArgumentsVoidBlock = () -> Void

protocol ErrorHandler: class {
    func handle(error: Error?, retryBlock: NoArgumentsVoidBlock?)
}

extension ErrorHandler {
    func handle(error: Error?, retryBlock: NoArgumentsVoidBlock?) {
        guard let error = error else { return }
        guard let alert = UIAlertController.alert(withError: error, retryHandler: retryBlock, cancelHandler: nil) else { return }
        (self as? UIViewController)?.present(alert, animated: true, completion: nil)
    }
}

extension UIAlertController {
    static func alert(from error: Error, withTitle title: String? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title ?? "Error", message: error.localizedDescription, preferredStyle: .alert)
        return alert
    }
    
    static func alert(withError error: Error?, title: String? = "Error", retryHandler: NoArgumentsVoidBlock?, cancelHandler: NoArgumentsVoidBlock?) -> UIAlertController? {
        guard let error = error else { return nil }
        let alert = UIAlertController.alert(from: error)
        
        if retryHandler != nil {
            alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { (_) in
                retryHandler?()
            }))
        }
        
        alert.addAction(UIAlertAction(title: retryHandler == nil ? "OK" : "Cancel", style: .cancel, handler: { (_) in
            cancelHandler?()
        }))
        
        return alert
    }
}
