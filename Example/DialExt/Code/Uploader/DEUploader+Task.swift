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
        
        public var data: Data? = nil
        
        public let completion: DEUploadCompletion
        
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
            
            let task = session.dataTask(with: request)
            self.task = task
            task.resume()
        }
        
        internal func updateProgress() {
            if let task = self.task, self.state == .loading {
                self.progress = min(Float(task.countOfBytesSent) / Float(task.countOfBytesExpectedToSend), 0.99)
            }
        }
        
    }
}
