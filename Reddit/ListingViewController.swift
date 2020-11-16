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
            tableView.prefetchDataSource = self
        }
    }
    var viewModel = ListingViewModel(service: RedditService())
    lazy var imageDownloadDebouncer = Debouncer(delay: 0.3) {
        self.tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchFresh()
    }
    
    @objc
    func fetchFresh() {
        viewModel.fetchData(offset: 0) { [unowned self] (error) in
            self.handle(error: error, retryBlock: { [unowned self] in self.fetchFresh() })
            self.performFetch()
        }
    }
    
    func performFetch() {
        DispatchQueue.main.async {
            try? self.viewModel.listingFetchedResultsController.performFetch()
            self.tableView.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "RedditPostTableViewCell", for: indexPath) as! RedditPostTableViewCell
        let item = viewModel.item(at: indexPath)
        cell.render(model: item)
        if item.shouldLoadImage {
            viewModel.downloadImage(at: indexPath) {
                self.imageDownloadDebouncer.call()
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.cancelImageDownloading(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension ListingViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let maxIndexPath = indexPaths.max() ?? IndexPath(row: 0, section: 0)
        let numberOfRows = self.tableView(tableView, numberOfRowsInSection: maxIndexPath.section)
        if numberOfRows - 1 == maxIndexPath.row {
            viewModel.fetchData(offset: maxIndexPath.row, completionHandler: { [unowned self] error in
                DispatchQueue.main.async {
                    self.performFetch()
                }
            })
        }
    }
}

class RedditPostTableViewCell: UITableViewCell {
    @IBOutlet weak var postedByTitle: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var commentsLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    struct Model {
        var postedBy: String
        var name: String
        var commentsTitle: String
        var image: UIImage?
        var shouldLoadImage: Bool
    }
    
    func render(model: Model) {
        postedByTitle.text = model.postedBy
        nameLabel.text = model.name
        commentsLabel.text = model.commentsTitle
        thumbnailImageView?.image = model.image
    }
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

class Debouncer {
    var callback: NoArgumentsVoidBlock
    var delay: Double
    weak var timer: Timer?
    
    init(delay: Double, callback: @escaping NoArgumentsVoidBlock) {
        self.delay = delay
        self.callback = callback
    }
    
    func call() {
        timer?.invalidate()
        let nextTimer = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(Debouncer.fireNow), userInfo: nil, repeats: false)
        timer = nextTimer
    }
    
    @objc func fireNow() {
        self.callback()
    }
}
