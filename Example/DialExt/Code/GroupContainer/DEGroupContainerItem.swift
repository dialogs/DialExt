//
//  DEGroupContainerItem.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 10/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation


public protocol DEGroupContainerItem: class {
    
    func readData(_ onSuccess: @escaping ((Data?) -> ()), onFailure: ((Error?) -> ())?)
    
    func writeData(_ data: Data, onFinish: ((Bool, Error?) -> ())?)
    
    func copyFile(from: URL, onFinish:((Bool, Error?) -> ())?)
    
    func copyFile(to: URL, onFinish:((Bool, Error?) -> ())?)
    
    func removeFile(onFinish:((Bool, Error?) -> ())?)
    
    /**
     * Does not being called if changes are initiated by this item
     */
    var onDidChange:(() -> ())? {get set}
}

public enum DEDebugContainerItemError: Error {
    
    /// Operation is unavailable because item is debug
    case unavailable
}

public class DEDebugContainerItem: DEGroupContainerItem {
    
    private var data: Data
    
    private let queue = DispatchQueue.global(qos: .utility)
    
    public var onDidChange: (() -> ())? = nil
    
    public init(data: Data) {
        self.data = data
    }
    
    public func readData(_ onSuccess: @escaping ((Data?) -> ()), onFailure: ((Error?) -> ())?) {
        self.queue.async {
            let data = self.data
            DispatchQueue.main.async {
                onSuccess(data)
            }
        }
    }
    
    public func writeData(_ data: Data, onFinish: ((Bool, Error?) -> ())?) {
        self.queue.async {
            self.data = data
            DispatchQueue.main.async {
                onFinish?(true, nil)
            }
        }
    }
    
    public func copyFile(to: URL, onFinish: ((Bool, Error?) -> ())?) {
        DispatchQueue.main.async {
            onFinish?(false, DEDebugContainerItemError.unavailable)
        }
    }
    
    public func copyFile(from: URL, onFinish: ((Bool, Error?) -> ())?) {
        DispatchQueue.main.async {
            onFinish?(false, DEDebugContainerItemError.unavailable)
        }
    }
    
    public func removeFile(onFinish: ((Bool, Error?) -> ())?) {
        DispatchQueue.main.async {
            onFinish?(false, DEDebugContainerItemError.unavailable)
        }
    }
}

public class DEGroupContainerFilePresenter: NSObject, DEGroupContainerItem {
    
    public static let commonWorkOperationQueue: OperationQueue = {
        let queue = OperationQueue.init()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .background
        queue.name = "im.dlg.group.file.presenter.commonQueue"
        return queue
    }()
    
    private static let commonOperationQueue: OperationQueue = {
        let queue = OperationQueue.init()
        queue.qualityOfService = .background
        queue.name = "im.dlg.group.file.coordination"
        return queue
    }()
    
    internal let url: URL
    
    private var coordinator: NSFileCoordinator!
    
    private var presenter: Presenter!
    
    private let workQueue: OperationQueue
    
    public let callbackQueue: DispatchQueue?
    
    public var onDidChange: (() -> ())? = nil
    
    init(url: URL,
         workQueue: OperationQueue = DEGroupContainerFilePresenter.commonWorkOperationQueue,
         callbackQueue: DispatchQueue? = DispatchQueue.main) {
        self.url = url
        
        let queue = OperationQueue.init()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .utility
        queue.name = "im.dlg.group.file.coordinator.private.\(url.absoluteString)"
        
        self.workQueue = queue
        self.callbackQueue = callbackQueue
   
        super.init()
        
        self.presenter = Presenter.init(url: self.url,
                                        queue: DEGroupContainerFilePresenter.commonOperationQueue,
                                        changeHandler: { [weak self] in
                                            withExtendedLifetime(self, {
                                                self?.presentedItemDidChange()
                                            })
        })
        
        self.coordinator = NSFileCoordinator.init(filePresenter: self.presenter)
    }
    
    deinit {
        self.coordinator = nil
        self.presenter = nil
    }
    
    public func presentedItemDidChange() {
        de_perform(code:self.onDidChange, on: self.callbackQueue)
    }
    
    // MARK: - Public
    
    public func readData(_ onSuccess: @escaping ((Data?) -> ()), onFailure: ((Error?) -> ())?) {
        let callbackQueue = self.callbackQueue
        self.workQueue.addOperation {
            var resultError: Error? = nil
            var isSuccess = false
            var data: Data? = nil
            
            var isDataCreationFailure = false
            var coordinatorError: NSError? = nil
            
            self.coordinator.coordinate(readingItemAt: self.url, options: [], error: &coordinatorError, byAccessor: { url in
                do {
                    data = try Data.init(contentsOf: url)
                    isSuccess = true
                }
                catch let error as NSError {
                    isDataCreationFailure = true
                    resultError = error
                }
            })
            
            if !isSuccess && !isDataCreationFailure {
                resultError = coordinatorError
            }

            de_perform(code: {
                if isSuccess {
                    onSuccess(data)
                }
                else {
                    onFailure?(resultError)
                }
            }, on: callbackQueue)
            
        }
    }
    
    public func copyFile(from: URL, onFinish: ((Bool, Error?) -> ())?) {
        let callbackQueue = self.callbackQueue
        self.workQueue.addOperation {
            var resultError: Error? = nil
            var isSuccess = false
            
            var isInBlockError = false
            var accessError: NSError? = nil
            self.coordinator.coordinate(writingItemAt: self.url, options: [.forReplacing], error: &accessError, byAccessor: { url in
                do {
                    let manager = FileManager.default
                    if manager.fileExists(atPath: self.url.path) {
                        try manager.removeItem(at: self.url)
                    }
                    try manager.copyItem(at: from, to: self.url)
                    isSuccess = true
                }
                catch let error {
                    isInBlockError = true
                    resultError = error
                }
            })
            
            if !isSuccess && !isInBlockError {
                resultError = accessError
            }
            
            de_perform(code: {
                if isSuccess {
                    onFinish?(true, nil)
                }
                else {
                    onFinish?(false, resultError)
                }
            }, on: callbackQueue)
            
        }
    }
    
    public func copyFile(to: URL, onFinish: ((Bool, Error?) -> ())?) {
        let callbackQueue = self.callbackQueue
        self.workQueue.addOperation {
            var resultError: Error? = nil
            var isSuccess = false
            
            var isInBlockError = false
            var accessError: NSError? = nil
            self.coordinator.coordinate(writingItemAt: self.url, options: [], error: &accessError, byAccessor: { url in
                do {
                    try FileManager.default.copyItem(at: self.url, to: to)
                    isSuccess = true
                }
                catch let error {
                    isInBlockError = true
                    resultError = error
                }
            })
            if !isSuccess && !isInBlockError {
                resultError = accessError
            }
            
            de_perform(code: {
                if isSuccess {
                    onFinish?(true, nil)
                }
                else {
                    onFinish?(false, resultError)
                }
            }, on: callbackQueue)
            
        }
        
    }
    
    public func writeData(_ data: Data, onFinish: ((Bool, Error?) -> ())?) {
        let callbackQueue = self.callbackQueue
        self.workQueue.addOperation {
            var resultError: Error? = nil
            var isSuccess = false
            var isInBlockError = false
            
            var accessError: NSError? = nil
            self.coordinator.coordinate(writingItemAt: self.url, options: [], error: &accessError, byAccessor: { url in
                do {
                    try data.write(to: url, options: [])
                    isSuccess = true
                }
                catch let error {
                    isInBlockError = true
                    resultError = error
                }
            })
            if !isSuccess && !isInBlockError {
                resultError = accessError
            }
            
            de_perform(code: {
                if isSuccess {
                    onFinish?(true, nil)
                }
                else {
                    onFinish?(false, resultError)
                }
            }, on: callbackQueue)
            
        }
    }
    
    public func removeFile(onFinish: ((Bool, Error?) -> ())?) {
        let callbackQueue = self.callbackQueue
        self.workQueue.addOperation {
            var resultError: Error? = nil
            var isSuccess = false
            var isInBlockError = false
            var accessError: NSError? = nil
            self.coordinator.coordinate(writingItemAt: self.url, options: [.forDeleting], error: &accessError, byAccessor: { url in
                do {
                    let manager = FileManager.default
                    if manager.fileExists(atPath: self.url.path) {
                        try manager.removeItem(at: self.url)
                    }
                    isSuccess = true
                }
                catch let error {
                    isInBlockError = true
                    resultError = error
                }
            })
            if !isSuccess && !isInBlockError {
                resultError = accessError
            }
            
            de_perform(code: {
                if isSuccess {
                    onFinish?(true, nil)
                }
                else {
                    onFinish?(false, resultError)
                }
            }, on: callbackQueue)
            
        }
    }
    
    
    // MARK: Presenter
    
    class Presenter: NSObject, NSFilePresenter {
        
        typealias ChangeHandler = () -> ()
        
        let url: URL
        
        let queue: OperationQueue
        
        let changeHandler: ChangeHandler
        
        init(url: URL, queue: OperationQueue, changeHandler: @escaping ChangeHandler) {
            self.url = url
            self.queue = queue
            self.changeHandler = changeHandler
        }
        
        public var presentedItemOperationQueue: OperationQueue {
            return self.queue
        }
        
        public var presentedItemURL: URL? {
            return self.url
        }
        
        public func presentedItemDidChange() {
            self.changeHandler()
        }
    }
    
}
