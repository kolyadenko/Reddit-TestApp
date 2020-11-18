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
}
