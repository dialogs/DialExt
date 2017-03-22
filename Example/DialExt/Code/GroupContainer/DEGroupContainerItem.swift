//
//  DEGroupContainerItem.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 10/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public  protocol DEGroupContainerItem {
    
    func readData(_ onSuccess: @escaping ((Data?) -> ()), onFailure: ((Error?) -> ())?)
    
    func writeData(_ data: Data, onFinish: ((Bool, Error?) -> ())?)
    
    func copyFile(from: URL, onFinish:((Bool, Error?) -> ())?)
    
    func copyFile(to: URL, onFinish:((Bool, Error?) -> ())?)

    
    var onDidChange:(() -> ())? {get set}
}

internal class DEGroupContainerFilePresenter: NSObject, DEGroupContainerItem, NSFilePresenter {
    private static let commonOperationQueue: OperationQueue = {
        let queue = OperationQueue.init()
        queue.qualityOfService = .background
        queue.name = "im.dlg.group.file.coordination"
        return queue
    }()
    
    internal let url: URL
    
    private var coordinator: NSFileCoordinator!
    
    private let workQueue: OperationQueue
    
    public var callbackQueue: DispatchQueue? = .main
    
    var onDidChange: (() -> ())?
    
    init(url: URL) {
        self.url = url
        
        let queue = OperationQueue.init()
        queue.qualityOfService = .background
        queue.name = "im.dlg.group.file.coordinator.private"
        self.workQueue = queue
        
        super.init()
        
        self.coordinator = NSFileCoordinator.init(filePresenter: self)
    }
    
    var presentedItemOperationQueue: OperationQueue {
        return DEGroupContainerFilePresenter.commonOperationQueue
    }
    
    var presentedItemURL: URL? {
        return self.url
    }
    
    func presentedItemDidChange() {
        de_perform(code:self.onDidChange, on: self.callbackQueue)
    }
    
    public func readData(_ onSuccess: @escaping ((Data?) -> ()), onFailure: ((Error?) -> ())?) {
        let callbackQueue = self.callbackQueue
        self.workQueue.addOperation {
            var resultError: NSError? = nil
            var isSuccess = false
            var data: Data? = nil
            self.coordinator.coordinate(readingItemAt: self.url, options: [], error: &resultError, byAccessor: { url in
                do {
                    data = try Data.init(contentsOf: url)
                    isSuccess = true
                }
                catch let error as NSError {
                    resultError = error
                }
            })
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
    
    func copyFile(from: URL, onFinish: ((Bool, Error?) -> ())?) {
        let callbackQueue = self.callbackQueue
        self.workQueue.addOperation {
            var resultError: Error? = nil
            var isSuccess = false
            
            var accessError: NSError? = nil
            self.coordinator.coordinate(writingItemAt: self.url, options: [], error: &accessError, byAccessor: { url in
                do {
                    let manager = FileManager.default
                    if manager.fileExists(atPath: self.url.path) {
                        try manager.removeItem(at: self.url)
                    }
                    try manager.copyItem(at: from, to: self.url)
                    isSuccess = true
                }
                catch let error {
                    resultError = error
                }
            })
            if accessError != nil {
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
    
    func copyFile(to: URL, onFinish: ((Bool, Error?) -> ())?) {
        let callbackQueue = self.callbackQueue
        self.workQueue.addOperation {
            var resultError: Error? = nil
            var isSuccess = false
            
            var accessError: NSError? = nil
            self.coordinator.coordinate(writingItemAt: self.url, options: [], error: &accessError, byAccessor: { url in
                do {
                    try FileManager.default.copyItem(at: self.url, to: to)
                    isSuccess = true
                }
                catch let error {
                    resultError = error
                }
            })
            if accessError != nil {
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
            
            var accessError: NSError? = nil
            self.coordinator.coordinate(writingItemAt: self.url, options: [], error: &accessError, byAccessor: { url in
                do {
                    try data.write(to: url, options: [])
                    isSuccess = true
                }
                catch let error {
                    resultError = error
                }
            })
            if accessError != nil {
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
    
}
