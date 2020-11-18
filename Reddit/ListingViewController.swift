//
//  ViewController.swift
//  Reddit
//
//  Created by Alexey Kolyadenko on 09.11.2020.
//

import UIKit
import CoreData

class ListingViewController: UIViewController, ErrorHandler {
    // MARK: Props
    var viewModel = ListingViewModel(service: RedditService())

    var items: [Post.PostData] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    lazy var imageDownloadDebouncer = Debouncer(delay: 0.3) {
        self.tableView.reloadData()
    }
    
    // MARK: Outlets
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.refreshControl = UIRefreshControl()
            tableView.refreshControl?.addTarget(self, action: #selector(fetchFresh), for: .valueChanged)
            tableView.prefetchDataSource = self
        }
    }

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchFresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: User actions
    @objc
    func fetchFresh() {
        viewModel.fetchData(offset: 0) { [unowned self] (error) in
            self.handle(error: error, retryBlock: { [unowned self] in self.fetchFresh() })
            self.performFetch()
        }
    }
    
    func performFetch() {
        try? self.viewModel.listingFetchedResultsController.performFetch()
        self.tableView.refreshControl?.endRefreshing()
        self.tableView.reloadData()
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showImage":
            if let viewController = segue.destination as? DetailedImageViewController, let url = sender as? URL {
                viewController.url = url
            }
        default:
            break
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let object = viewModel.listingFetchedResultsController.object(at: indexPath)
        guard let url = object.destinationUrl else { return }
        performSegue(withIdentifier: "showImage", sender: url)
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return viewModel.listingFetchedResultsController.object(at: indexPath).destinationUrl != nil
    }
}

extension ListingViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let maxIndexPath = indexPaths.max() ?? IndexPath(row: 0, section: 0)
        let numberOfRows = self.tableView(tableView, numberOfRowsInSection: maxIndexPath.section)
        if numberOfRows - 1 == maxIndexPath.row {
            viewModel.fetchData(offset: maxIndexPath.row, completionHandler: { [unowned self] error in
                self.performFetch()
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
        thumbnailImageView.superview?.isHidden = model.image == nil
    }
}
