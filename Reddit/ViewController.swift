//
//  ViewController.swift
//  Reddit
//
//  Created by Alexey Kolyadenko on 09.11.2020.
//

import UIKit

class ViewController: UIViewController {
    
    let service: RedditService = .init()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        service.fetchTopPosts(offset: 0, completionHandler: { listing, error in
            print(listing)
        })
    }


}

