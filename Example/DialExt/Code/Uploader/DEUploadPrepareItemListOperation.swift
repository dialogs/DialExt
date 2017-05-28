//
//  DEUploadPrepareItemListOperation.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 27/05/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation


public class DEUploadPrepareItemListOperation: DLGAsyncOperation<[DEUploadPreparedItem]> {
    
    public let items: [NSExtensionItem]
    
    public init(items: [NSExtensionItem]) {
        self.items = items
    }
    
    public override func onDidStart() {
        
        guard self.items.count > 0 else {
            self.finish(result: DLGAsyncOperationResult.success([]))
            return
        }
        
        items.enumerated().forEach({ idx, item in
            let operation = DEUploadPrepareItemOperation.init(extensionItem: item)
            operation.onDidFinish = { [weak self] result in
                withOptionalExtendedLifetime(self, body: {
                    DispatchQueue.main.async {
                        self!.handle(result: result, idx: idx)
                    }
                })
            }
            self.queue.addOperation(operation)
        })
    }
    
    public override func cancel() {
        self.queue.cancelAllOperations()
        super.cancel()
    }
    
    private var failed: Bool = false
    
    private let queue: OperationQueue = {
        let queue = OperationQueue.init()
        queue.qualityOfService = .userInitiated
        queue.name = "im.dlg.extension.item_list.preparing"
        return queue
    }()
    
    private var results: [ResultEntry] = []
    
    private var resultsCollected: Bool {
        return results.count == self.items.count
    }
    
    private typealias ResultEntry = (prepared: DEUploadPreparedItem, idx: Int)
    
    private func handle(result: DLGAsyncOperationResult<DEUploadPreparedItem>, idx: Int) {
        guard !self.failed else {
            return
        }
        
        switch result {
            
        case let .success(item):
            self.results.append((item!, idx))
            if resultsCollected {
                let sortedResults = self.results.sorted(by: { $0.0.idx > $0.1.idx})
                let items = sortedResults.map{ $0.prepared }
                self.finish(result: DLGAsyncOperationResult.success(items))
            }
            
        case .cancelled: return
            
        case let .failure(error):
            self.failed = true
            self.finishWithFailure(error: error)
            
        default:
            fatalError("Unexpected item prepare result: \(result)")
        }
    }
}
