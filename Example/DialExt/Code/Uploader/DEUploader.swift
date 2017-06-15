import Foundation

public typealias DEUploadCompletion = ((Bool, Error?) -> ())

public typealias DEUploadProgressCallback = ((Float) -> ())

public protocol DEUploaderable {
    
    var isUploading: Bool { get }
    
    func cancel()
    
    func perform(task: DEUploadPreparedTask,
                 progressCallback: DEUploadProgressCallback?,
                 completion: @escaping DEUploadCompletion) throws
}


public final class DEUploader: NSObject, DEUploaderable, URLSessionDelegate {
    
    public var isUploading: Bool {
        return self.currentTask != nil
    }
    
    public init(requestBuilder: DEUploadRequestBuilderable) {
        self.requestBuilder = requestBuilder
    }
    
    convenience public init(apiUrl: URL) {
        self.init(requestBuilder: DEUploadRequestBuilder.init(apiUrl: apiUrl))
    }
    
    public func perform(task: DEUploadPreparedTask,
                        progressCallback: DEUploadProgressCallback?,
                        completion: @escaping DEUploadCompletion) throws {
        
        guard !self.isUploading else {
            throw DEUploadError.busy
        }
        
        let request = try self.requestBuilder.buildRequest(task: task)
        let internalCompletion: DEUploadCompletion = { [weak self] success, error in
            withOptionalExtendedLifetime(self, body: {
                self?.releaseCurrentTask()
                completion(success, error)
            })
        }
        let task = Task.init(sourceTask: task,
                             request: request,
                             progressCallback: progressCallback,
                             completion: internalCompletion)
        self.currentTask = task
        task.run(session: self.session)
    }
    
    deinit {
        cancel()
    }
    
    public func cancel() {
        if let task = self.currentTask {
            task.cancel()
        }
    }
    
    // MARK: - Private Vars
    
    private let requestBuilder: DEUploadRequestBuilderable
    
    private var currentTask: Task? = nil
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        return URLSession.init(configuration: .default, delegate: self, delegateQueue: .main)
    }()
    
    // MARK: - Private Methods
    
    private func releaseCurrentTask() {
        self.currentTask = nil
    }
    
    // MARK: - URLSessionDataDelegate
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        if let task = self.currentTask {
            task.updateProgress()
        }
    }
    
    /*
     public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
     
     guard let sender = challenge.sender else {
     fatalError()
     }
     sender.continueWithoutCredential(for: challenge)
     
     let credential = URLCredential.init(trust: challenge.protectionSpace.serverTrust!)
     completionHandler(URLSession.AuthChallengeDisposition.useCredential, credential)
     }
     */
}

