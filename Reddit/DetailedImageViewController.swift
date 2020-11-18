//
//  DetailedImageViewController.swift
//  Reddit
//
//  Created by Alexey Kolyadenko on 16.11.2020.
//

import UIKit
import WebKit

class DetailedImageViewController: UIViewController {
    @IBOutlet weak var webView: WKWebView!
    var url: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.load(URLRequest(url: url))
    }
    
    // MARK: Restoration
    let urlRestorationKey = "DetailedImageViewController.URL"

    override func encodeRestorableState(with coder: NSCoder) {
        coder.encode(url.absoluteString, forKey: urlRestorationKey)
        super.encodeRestorableState(with: coder)
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        if let urlString = coder.decodeObject(forKey: urlRestorationKey) as? String {
            url = URL(string: urlString)
            webView.load(URLRequest(url: url))
        }
        super.decodeRestorableState(with: coder)
    }
}
