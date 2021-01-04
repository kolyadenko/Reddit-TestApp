//
//  ImageService.swift
//  Reddit
//
//  Created by Alexey Kolyadenko on 25.11.2020.
//

import UIKit

typealias NetworkServiceToken = UUID
typealias ImageCompletionBlock = (Result<UIImage, Error>) -> Void
typealias CompletionBlock = (Result<Data, Error>) -> Void

protocol NetworkService {
    func getData(url: URL, completionHandler: CompletionBlock) -> NetworkServiceToken
    func cancel(_ token: NetworkServiceToken)
}

protocol ImageServiceProtocol {
    func downloadImage(with url: URL, completionHandler: @escaping ImageCompletionBlock) -> InvalidatableToken?
}

struct InvalidatableToken {
  var cancelBlock: (() -> Void)?
  
  func cancel() {
    cancelBlock?()
  }
}

class Task {
    var cancelToken: InvalidatableToken?
    private var completionHandlers: [UUID: ImageCompletionBlock] = [:]
    
    func addCompletionHandler(_ completionHandler: @escaping ImageCompletionBlock) -> InvalidatableToken {
        let closureIdentifier = UUID()
        self.completionHandlers[closureIdentifier] = completionHandler
        let invalidatableToken = InvalidatableToken { [unowned self] in
            self.completionHandlers[closureIdentifier] = nil
            if self.completionHandlers.isEmpty {
                cancelToken?.cancel()
            }
        }
        return invalidatableToken
    }
    
    func executeCompletionHandlers(with result: Result<UIImage, Error>) {
        completionHandlers.forEach({ item in
            item.value(result)
        })
        completionHandlers.removeAll()
    }
}

class ImageService: ImageServiceProtocol {
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    var networkService: NetworkService
    var cache = NSCache<NSString, UIImage>()
    var tasks: [String: Task] = [:]
    
    func downloadImage(with url: URL, completionHandler: @escaping ImageCompletionBlock) -> InvalidatableToken? {
        if let task = tasks[url.absoluteString] {
            // Add completion to current task and return token
            return task.addCompletionHandler(completionHandler)
        }
        
        let task = Task()
        
        if let image = cache.object(forKey: url.absoluteString as NSString) {
            // Execute completion block with cached image and return nil as token (there is no need to use it)
            completionHandler(.success(image))
            return nil
        }
        
        // Aquire network token from network client
        let networkToken = networkService.getData(url: url) { [weak task, unowned self] (result) in
            guard let task = task else { return }
            switch result {
            case .success(let data):
                let image = UIImage(data: data)!
                cache.setObject(image, forKey: url.absoluteString as NSString)
                task.executeCompletionHandlers(with: .success(image))
            case .failure(let error):
                task.executeCompletionHandlers(with: .failure(error))
            }
            self.tasks[url.absoluteString] = nil
        }
        
        // Wrap network token with InvalidatableToken
        let networkInvalidatableToken = InvalidatableToken(cancelBlock: { [unowned self] in
            self.networkService.cancel(networkToken)
        })
        
        // Set it as last resort for task
        task.cancelToken = networkInvalidatableToken
        
        // Add completion and return as you were
        return task.addCompletionHandler(completionHandler)
    }
}
