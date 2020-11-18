//
//  Utility.swift
//  Reddit
//
//  Created by Alexey Kolyadenko on 18.11.2020.
//

import UIKit

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
