import Foundation

internal extension DEUploader {
    
    internal class Task: NSObject, URLSessionTaskDelegate {
        
        enum State: Int {
            case idle
            case loading
            case cancelled
        }
        
        let sourceTask: DEUploadPreparedTask
        
        let request: URLRequest
        
        private let progressCallback: DEUploadProgressCallback?
        
        private let completion: DEUploadCompletion
        
        private(set) var progress: Float = 0.0 {
            didSet {
                if progress != oldValue {
                    self.progressCallback?(progress)
                }
            }
        }
        
        private(set) var state: State = .idle
        
        private var task: URLSessionTask? = nil
        
        private var isCancellable: Bool {
            return self.state == .loading
        }
        
        init(sourceTask: DEUploadPreparedTask,
             request: URLRequest,
             progressCallback: DEUploadProgressCallback?,
             completion: @escaping DEUploadCompletion) {
            self.sourceTask = sourceTask
            self.request = request
            self.progressCallback = progressCallback
            self.completion = completion
        }
        
        func cancel() {
            guard self.isCancellable else {
                return
            }
            
            self.state = .cancelled
            if let task = self.task {
                task.cancel()
            }
        }
        
        func run(session: URLSession) {
            guard self.state == .idle else {
                return
            }
            
            self.state = .loading
            
            let task = session.dataTask(with: request) { [weak self] (data, response, error) in
                withExtendedLifetime(self, {
                    self?.handleTaskCompleted(data: data, response: response, error: error)
                })
            }
            task.resume()
            self.task = task
        }
        
        func updateProgress() {
            if let task = self.task, self.state == .loading {
                self.progress = Float(task.countOfBytesSent) / Float(task.countOfBytesExpectedToSend)
            }
        }
        
        private func handleTaskCompleted(data: Data?, response: URLResponse?, error: Error?) {
            guard self.state == .loading else {
                return
            }
            
            var success = (data != nil)
            var resultError = error
            
            if success || resultError == nil {
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode != 200 {
                        success = false
                        
                        resultError = NSError.httpError(statusCode: httpResponse.statusCode, data: data)
                    }
                }
            }
            
            self.completion(success, resultError)
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            guard let sender = challenge.sender else {
                fatalError()
            }
            sender.continueWithoutCredential(for: challenge)
            
            let credential = URLCredential.init(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(URLSession.AuthChallengeDisposition.useCredential, credential)
        }
        
        public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            
            guard let sender = challenge.sender else {
                fatalError()
            }
            sender.continueWithoutCredential(for: challenge)
            
            let credential = URLCredential.init(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(URLSession.AuthChallengeDisposition.useCredential, credential)
        }

    }
}
