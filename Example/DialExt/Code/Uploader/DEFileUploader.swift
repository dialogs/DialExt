//
//  DEFileUploader.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 16/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public typealias DEFileUploadCompletion = ((Bool, Error?) -> ())

public typealias DEFileUploadProgressCallback = ((Float) -> ())

public protocol DEFileUploaderable {
    
    var isUploading: Bool { get }
    
    func upload(_ file: DEFileUploader.File,
                recipient: DEFileUploader.Recipient,
                progressCallback: DEFileUploadProgressCallback?,
                completion: DEFileUploadCompletion?) throws
}


public enum DEFileUploadError: Error {
    case invalidAuthInfo
    case invalidAccessHash
    case busy
}

final public class DEFileUploader: NSObject, DEFileUploaderable, URLSessionDataDelegate {
    
    public var isUploading: Bool {
        return self.currentTask != nil
    }
    
    public init(tokenProvider: DEFileUploadTokenInfoProvidable,
                endpoints: [String]) {
        self.tokenProvider = tokenProvider
        self.endpoints = endpoints
        
        super.init()
        
        self.session = URLSession.init(configuration: .default, delegate: self, delegateQueue: .main)
    }
    
    deinit {
        if let task = self.currentTask {
            task.cancel()
        }
    }
    
    public func upload(_ file: DEFileUploader.File,
                       recipient: DEFileUploader.Recipient,
                       progressCallback: DEFileUploadProgressCallback?,
                       completion: DEFileUploadCompletion?) throws {
        
        guard !self.isUploading else {
            throw DEFileUploadError.busy
        }
        
        guard let url = URL(string: endpoints.first!) else {
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: nil)
        }
        
        guard let authInfo = tokenProvider.authInfo else {
            throw DEFileUploadError.invalidAuthInfo
        }
        
        guard let accessHash = tokenProvider.accessHash else {
            throw DEFileUploadError.invalidAccessHash
        }
        
        self.currentTaskProgressCallback = progressCallback
        
        let sender = DEFileUploader.RequestBuilder.Sender.init(accessHash: accessHash)
        
        let info = DEFileUploader.RequestBuilder.UploadInfo.init(url: url,
                                                                 file: file,
                                                                 sender: sender,
                                                                 recipient: recipient,
                                                                 authInfo: authInfo)
        let request = requestBuilder.buildRequest(info: info)
        
        let task = session.dataTask(with: request) { [weak self] (data, response, error) in
            withExtendedLifetime(self, {
                guard self != nil else { return }
                
                self?.handleTaskCompleted(data: data, response: response, error: error)
                completion?(data != nil, error)
            })
        }
        
        self.currentTask = task
        
        task.resume()
    }
    
    // MARK: - Private Vars
    
    private var session: URLSession!
    
    private let tokenProvider: DEFileUploadTokenInfoProvidable
    
    private let requestBuilder = RequestBuilder.init()
    
    private let endpoints: [String]
    
    private var currentTask: URLSessionDataTask? = nil
    
    private var currentTaskProgressCallback: DEFileUploadProgressCallback? = nil
    
    // MARK: - Private Funcs
    
    private func handleTaskCompleted(data: Data?, response: URLResponse?, error: Error?) {
        self.currentTask = nil
        self.currentTaskProgressCallback = nil
    }
    
    // MARK: - URLSessionDataDelegate
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        if self.currentTask == task, let callback = self.currentTaskProgressCallback {
            let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
            callback(progress)
        }
    }
}


final public class DEDebugFileUploader {
    
    public enum Config {
        case performWithSuccess
        case performWithFailure(Error?)
    }
    
    public var config: Config = .performWithSuccess
    
    public func upload(_ file: DEFileUploader.File, recipient: DEFileUploader.Recipient, completion: DEFileUploadCompletion?) {
        switch self.config {
        case .performWithSuccess:
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1000, execute: { 
                completion?(true, nil)
            })
        case let .performWithFailure(error):
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1000, execute: {
                completion?(false, error)
            })
        }
    }
    
}
