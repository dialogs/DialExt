import Foundation


public class DEAuthChallengeConfig {
    
    public static let shared = DEAuthChallengeConfig.init()
    
    /// Override resolver to resolve auth challenges from shared data uploading
    public var resolver: DEAuthChallengeResolver? = nil
    
    public init() {
        self.resolver = nil
    }
}

public protocol DEAuthChallengeResolver {
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
}

public typealias DEUploadCompletion = ((Bool, Error?) -> ())

public typealias DEUploadProgressCallback = ((Float) -> ())

public protocol DEUploaderable {
    
    var isUploading: Bool { get }
    
    func cancel()
    
    func perform(task: DEUploadPreparedTask,
                 progressCallback: DEUploadProgressCallback?,
                 completion: @escaping DEUploadCompletion) throws
    
    func resetUploadUrl(_ url: URL)
}


public final class DEUploader: NSObject, DEUploaderable, URLSessionDataDelegate {
    
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
    
    public func resetUploadUrl(_ url: URL) {
        self.requestBuilder.resetApiUrl(url)
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
        if let currentTask = self.currentTask {
            currentTask.updateProgress()
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let currentTask = self.currentTask {
            
            self.currentTask = nil
            
            let fail: ((Error?) -> ()) = { error in
                let resultError = error ?? DEUploadError.unknownError
                DEErrorLog("Share item uploading failed. \(resultError)")
                currentTask.completion(false, resultError)
            }
            
            guard error == nil else {
                fail(error)
                return
            }
            
            guard let data = currentTask.data, let response = task.response as? HTTPURLResponse else {
                // error
                fail(nil)
                return
            }
            
            guard response.statusCode == 200 else {
                
                if response.statusCode == 413,
                    let value = response.allHeaderFields["X-Max-Size"],
                    let maxSize = value as? String,
                    let maxSizeBytes = Int64.init(maxSize) {
                    fail(DEUploadError.fileLengthExceedsKnownMaximum(maximum: maxSizeBytes))
                    return
                }
                
                DESLog("Sharing upload failed", level: .error)
                let message = String.init(data: data, encoding: .utf8) ?? ""
                DELog("Sharing upload failed, status code: \(response.statusCode), message: \(message)")
                let targetError = NSError.httpError(statusCode: response.statusCode, data: data)
                fail(targetError)
                return
            }
            
            DESLog("Sharing upload finished with success")
            currentTask.completion(true, nil)
        }
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.currentTask?.data = data
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let resolver = DEAuthChallengeConfig.shared.resolver {
            resolver.urlSession(session, didReceive: challenge, completionHandler: completionHandler)
        }
        else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
}

