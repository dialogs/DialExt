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
    
    func cancel()
    
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
    
    public var currentTaskProgressCallback: DEFileUploadProgressCallback? = nil
    
    public init(tokenProvider: DEFileUploadTokenInfoProvidable,
                endpoints: [URL]) {
        self.tokenProvider = tokenProvider
        self.endpoints = endpoints
        
        super.init()
        
        self.session = URLSession.init(configuration: .default, delegate: self, delegateQueue: .main)
    }
    
    deinit {
        cancel()
    }
    
    public func cancel() {
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
        
        guard let url = self.endpoints.first else {
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: nil)
        }
        
        guard let authInfo = tokenProvider.authInfo else {
            throw DEFileUploadError.invalidAuthInfo
        }
        
        self.currentTaskProgressCallback = progressCallback
        
        let info = DEFileUploader.RequestBuilder.UploadInfo.init(url: url,
                                                                 file: file,
                                                                 recipient: recipient,
                                                                 authInfo: authInfo)
        let request = requestBuilder.buildRequest(info: info)
        
        let task = session.dataTask(with: request) { [weak self] (data, response, error) in
            withOptionalExtendedLifetime(self, body: {
                self?.handleTaskCompleted(data: data, response: response, error: error, completion: completion)
            })
        }
        
        self.currentTask = task
        
        task.resume()
    }
    
    // MARK: - Private Vars
    
    private var session: URLSession!
    
    private let tokenProvider: DEFileUploadTokenInfoProvidable
    
    private let requestBuilder = RequestBuilder.init()
    
    private let endpoints: [URL]
    
    private var currentTask: URLSessionDataTask? = nil
    
    // MARK: - Private Funcs
    
    private func handleTaskCompleted(data: Data?,
                                     response: URLResponse?,
                                     error: Error?,
                                     completion: DEFileUploadCompletion?) {
        self.currentTask = nil
        self.currentTaskProgressCallback = nil
        
        completion?(data != nil, error)
    }
    
    // MARK: - URLSessionDataDelegate
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        if self.currentTask == task, let callback = self.currentTaskProgressCallback {
            let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
            callback(progress)
        }
    }
}


final public class DEDebugFileUploader: DEFileUploaderable {
    
    public struct Config {
        
        var result: Result = .success
        
        var duration: TimeInterval = 3.0
        
        var progressCallbackPerformCount: Int = 10
        
        var progressFragmentValue: Float {
            return 1.0 / Float(progressCallbackPerformCount + 1)
        }
        
        var progressFragmentInterval: TimeInterval {
            return duration / TimeInterval(progressCallbackPerformCount + 1)
        }
        
        public enum Result {
            case success
            case failure(Error?)
        }
        
    }
    
    public func cancel() {
        self.resetCurrentTask()
    }
    
    public var currentTaskProgressCallback: DEFileUploadProgressCallback?
    
    public var isUploading: Bool {
        return self.currentTaskUuid != nil
    }
    
    public var progress = LimitedValueType<Float>.init(value: 0.0, minValue: 0.0, maxValue: 1.0)
    
    public var config: Config = Config.init()
    
    public init() {
        
    }
    
    deinit {
        print("deiniting")
    }
    
    public func hasCurrentTaskUuid(_ uuid: UUID) -> Bool {
        guard let currentUuid = self.currentTaskUuid else {
            return false
        }
        return currentUuid == uuid
    }
    
    public func upload(_ file: DEFileUploader.File,
                       recipient: DEFileUploader.Recipient,
                       progressCallback: DEFileUploadProgressCallback?,
                       completion: DEFileUploadCompletion?) throws {
        
        guard self.currentTaskUuid == nil else {
            throw DEFileUploadError.busy
        }
        
        let uuid = UUID.init()
        self.currentTaskUuid = uuid
        self.currentTaskProgressCallback = progressCallback
        
        let result = config.result
        let duration: TimeInterval = max(0.0, config.duration)
            
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            withOptionalExtendedLifetime(self, body: {
                self?.handleTaskCompletion(uuid, result: result, completion: completion)
            })
        }
        
        let progressFragment = config.progressFragmentValue
        let progressFragmentInterval = config.progressFragmentInterval
        self.increaseProgress(by: progressFragment, uuid: uuid, nextCallInterval: progressFragmentInterval)
    }
    
    private var currentTaskUuid: UUID? = nil
    
    private func handleTaskCompletion(_ taskUuid: UUID, result: Config.Result, completion: DEFileUploadCompletion?) {
        guard self.hasCurrentTaskUuid(taskUuid) else {
            return
        }
        
        self.resetCurrentTask()
        
        switch result {
        case .success:
            completion?(true, nil)
        case let .failure(error):
            completion?(false, error)
        }
    }
    
    private func resetCurrentTask() {
        self.currentTaskUuid = nil
        self.currentTaskProgressCallback = nil
        self.progress.value = 0.0
    }
    
    private func increaseProgress(by progressFragment: Float, uuid: UUID, nextCallInterval: TimeInterval) {
        guard self.hasCurrentTaskUuid(uuid) else {
            return
        }
        
        self.progress.value += progressFragment
        self.currentTaskProgressCallback?(self.progress.value)
        
        let shouldRecall = self.progress.value < 1.0
        
        if shouldRecall {
            DispatchQueue.main.asyncAfter(deadline: .now() + nextCallInterval ) { [weak self] in
                self?.increaseProgress(by: progressFragment, uuid: uuid, nextCallInterval: nextCallInterval)
            }
        }

    }
    
}
