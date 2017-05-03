//
//  DEExtensionItemUploader.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 21/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation


public enum DEExtensionItemUploaderError: Error {
    case noItemsToLoad
    case noItemsDataToLoad
}

/**
 * Supposed to work on **main thread** only!
 * - warning: For now supports uploading only one file at a time.
 */
public class DEExtensionItemUploader {
    
    // MARK: - Nested
    
    /**
     * Describes task to do.
     * Contains items passed from extension context and target dialogs (to send items to).
     */
    public class Task {
        
        public private(set) var items: [NSExtensionItem]
        
        public private(set) var dialogs: [AppSharedDialog]
        
        public init(items: [NSExtensionItem], dialogs: [AppSharedDialog]) {
            self.items = items
            self.dialogs = dialogs
        }
        
    }
    
    
    // MARK: - Vars
    
    /// Currently performing task. Nil there is no task performing right now.
    public private(set) var currentTask: Task? {
        didSet {
            resetProgress()
        }
    }
    
    /// Shortcut for checking is there any task performing right now.
    public var isUploading: Bool {
        return currentTask != nil
    }
    
    /// Callback for notifying about finishing current task.
    public var onDidFinish:((_ success: Bool, _ error: Error?) -> ())? = nil
    
    /// Value from 0.0 to 1.0, describing current task progress. 0.0 if no task in progress.
    public var progress: Float = 0.0
    
    /// Callback for notifying about finishing current task.
    public var onDidChangeProgress:((Float) -> ())? = nil
    
    // MARK: - Funcs
    
    /// Creates and returns new yploader instance.
    public init(fileUploader: DEFileUploaderable) {
        self.fileUploader = fileUploader
    }
    
    /// Cancels current task. Callback will not be called. Do nothing if there is no current task.
    public func cancel() {
        self.fileUploader.cancel()
        self.currentTask = nil
    }
    
    /// Starts uploading task. Returns *false* if any task is already performing.
    @discardableResult public func upload(task: Task) -> Bool {
        guard !self.isUploading else {
            return false
        }
        
        self.currentTask = task
        
        self.processCurrentTask()
        
        return true
    }
    
    public func isInProgressTask(_ task: Task) -> Bool {
        return task === self.currentTask
    }
    
    // MARK: - Private: Nested
    
    private class TaskItem: Hashable {
        
        let item: NSExtensionItem
        
        let attachment: NSItemProvider
        
        let fileExtension: String?
        
        public init(item: NSExtensionItem, attachment: NSItemProvider, fileExtension: String?) {
            self.item = item
            self.attachment = attachment
            self.fileExtension = fileExtension
        }
        
        public static func ==(lhs: TaskItem, rhs: TaskItem) -> Bool {
            return lhs === rhs
        }
        
        public var hashValue: Int {
            return ObjectIdentifier.init(self).hashValue
        }
        
    }
    
    // MARK: - Private: Vars
    
    private var fileUploader: DEFileUploaderable
    
    // MARK: - Private: Funcs
    
    private func processCurrentTask() {
        let task = self.currentTask!
        
        var taskItems: [TaskItem] = []
        
        let items = task.items
        for item in items {
            if let attachment = item.firstFoundDataRepresentableAttachment {
                let fileExtension = attachment.supposedFileExtension
                let taskItem = TaskItem.init(item: item, attachment: attachment, fileExtension: fileExtension)
                taskItems.append(taskItem)
            }
        }
        
        guard taskItems.count > 0 else {
            finishCurrentTask(success: false, error: DEExtensionItemUploaderError.noItemsToLoad)
            return
        }
        
        loadExtensionItemsData(task: task, items: taskItems)
    }
    
    private func finishTask(task: Task, success: Bool, error: Error?) {
        guard self.isInProgressTask(task) else {
            return
        }
        
        finishCurrentTask(success: success, error: error)
    }
    
    private func finishCurrentTask(success: Bool, error: Error?) {
        guard self.currentTask != nil else {
            return
        }
        
        self.currentTask = nil
        
        onDidFinish?(success, error)
    }
    
    private func uploadTaskItemResults(_ results: [TaskItem : Data], task: Task) {
        guard isInProgressTask(task) else {
            return
        }
        
        guard results.count > 0 else {
            self.finishCurrentTask(success: false, error: DEExtensionItemUploaderError.noItemsDataToLoad)
            return
        }
        
        var nameIndex = 0
        let files: [DEFileUploader.File] = results.map { (item, data) in
            var name = "File \(nameIndex)"
            if let fileExtension = item.fileExtension {
                name.append(".\(fileExtension)")
            }
            let mimetype = item.attachment.supposedMimeType ?? "application/octet-stream"
            let file = DEFileUploader.File.init(name: name, data: data, mimetype: mimetype)
            
            nameIndex += 1
            
            return file
        }
        self.uploadFiles(files, task: task)
    }
    
    private func uploadFiles(_ files: [DEFileUploader.File], task: Task) {
        guard isInProgressTask(task) else {
            return
        }
        let file = files.first!
        let dialog = task.dialogs.first!
        let recipient = DEFileUploader.Recipient.init(dialog: dialog)
        try! self.fileUploader.upload(file, recipient: recipient, progressCallback: { [weak self] (progress) in
            withOptionalExtendedLifetime(self) {
                self!.updateProgress(value: progress, task: task, notify: true)
            }
        }) { [weak self] success, error in
            withOptionalExtendedLifetime(self) {
                self!.finishTask(task: task, success: success, error: error)
            }
        }
    }
    
    private func loadExtensionItemsData(task: Task, items: [TaskItem]) {
        guard isInProgressTask(task) else {
            return
        }
        
        var results: [TaskItem : Data] = [:]
        
        let group = DispatchGroup.init()
        
        for item in items {
            group.enter()
            let loadStarted = item.attachment.loadAndRepresentData(options: nil, completionHandler: { (data, error) in
                if let resultData = data {
                    results[item] = resultData
                }
                group.leave()
            })
            guard loadStarted else {
                fatalError("Item is not data representable!")
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            withOptionalExtendedLifetime(self, body: {
                self!.uploadTaskItemResults(results, task: task)
            })
        }
    }
    
    private func resetProgress(notify: Bool = false) {
        self.updateProgress(value: 0.0, notify: notify)
    }
    
    private func updateProgress(value: Float, task: Task? = nil, notify: Bool = true) {
        guard task == nil || isInProgressTask(task!) else {
            return
        }
        
        self.progress = value
        if notify, let progressCallback = self.onDidChangeProgress {
            progressCallback(value)
        }
    }
}
