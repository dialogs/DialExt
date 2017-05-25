//
//  DEExtensionItemUploader.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 21/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation


public protocol DEExtensionItemUploading: class {
    
    var isUploading: Bool { get }
    
    /// Value from 0.0 to 1.0, describing current task progress. 0.0 if no task in progress.
    var progress: Float { get }

    /// Callback for notifying about finishing current task.
    var onDidFinish:((_ success: Bool, _ error: Error?) -> ())? { get set }
    
    /// Callback for notifying about finishing current task.
    var onDidChangeProgress:((Float) -> ())? { get set }
    
    /// Starts uploading task. Returns *false* and does nothing if any task is already performing.
    @discardableResult func upload(task: DEUploadTask) -> Bool
    
    
}

/**
 * Describes task to do.
 * Contains items passed from extension context and target dialogs (to send items to).
 */
public class DEUploadTask: Equatable {
    
    public private(set) var items: [NSExtensionItem]
    
    public private(set) var dialogs: [AppSharedDialog]
    
    private let uuid = UUID.init()
    
    public init(items: [NSExtensionItem], dialogs: [AppSharedDialog]) {
        self.items = items
        self.dialogs = dialogs
    }
    
    public static func ==(lhs: DEUploadTask, rhs: DEUploadTask) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
}


/**
 * Supposed to work on **main thread** only!
 * - warning: For now supports uploading only one file at a time.
 */
public class DEExtensionItemUploader: DEExtensionItemUploading {
    
    // MARK: - Vars
    
    /// Currently performing task. Nil there is no task performing right now.
    public private(set) var currentTask: DEUploadTask? {
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
    public init(fileUploader: DEUploaderable,
                authProvider: DEUploadAuthProviding,
                preparer: DEUploadShareExtensionItemPreparing = DEUploadShareExtensionItemPreparer.init()) {
        self.uploader = fileUploader
        self.preparer = preparer
        self.authProvider = authProvider
    }
    
    /// Cancels current task. Callback will not be called. Do nothing if there is no current task.
    public func cancel() {
        self.uploader.cancel()
        
        self.currentTask = nil
    }
    
    /// Starts uploading task. Returns *false* and does nothing if any task is already performing.
    @discardableResult public func upload(task: DEUploadTask) -> Bool {
        guard !self.isUploading else {
            return false
        }
        
        self.currentTask = task
        self.processCurrentTask()
        
        return true
    }
    
    // MARK: - Private: Vars
    
    /// Prepares items by converting from extensions to uploadable items
    private let preparer: DEUploadShareExtensionItemPreparing
    
    /// Uploads items to server
    private let uploader: DEUploaderable
    
    /// Provides data for signing url requests
    private let authProvider: DEUploadAuthProviding
    
    
    // MARK: - Private: Funcs
    
    private func handleItemsPrepared(items: [DEUploadPreparedItem], task: DEUploadTask) {
        guard isCurrentTask(task) else {
            return
        }
        
        let task = self.currentTask!
        let recipients = task.dialogs.map({ return DEUploadRecipient.init(dialog: $0) })
        let auth = try! self.authProvider.provideAuth()
        
        let preparedTask = DEUploadPreparedTask.init(recipients: recipients, items: items, auth: auth)
        do {
            try self.uploader.perform(task: preparedTask, progressCallback: { [weak self] progress in
                self?.updateProgress(value: progress, task: task, notify: true)
                }, completion: { [weak self] success, error in
                    self?.finishTask(task: task, success: success, error: error)
            })
        }
        catch {
            handleFailure(error: error, task: task)
        }
       
    }
    
    
    // MARK: - Task Control
    
    private func finishTask(task: DEUploadTask, success: Bool, error: Error?) {
        guard self.isCurrentTask(task) else {
            return
        }
        
        self.currentTask = nil
        onDidFinish?(success, error)
    }
    
    private func isCurrentTask(_ task: DEUploadTask?) -> Bool {
        return self.currentTask == task && task != nil
    }
    
    private func handleFailure(error: Error?, task: DEUploadTask) {
        self.finishTask(task: task, success: false, error: error)
    }
    
    private func processCurrentTask() {
        let task = self.currentTask!
        
        self.preparer.prepare(items: task.items) { [weak self] (preparedItems, error) in
            withOptionalExtendedLifetime(self, body: {
                if let items = preparedItems {
                    self!.handleItemsPrepared(items: items, task: task)
                }
                else {
                    self!.handleFailure(error: error, task: task)
                }
            })
        }
    }
    
    
    // MARK: - Progress
    
    private func resetProgress(notify: Bool = false) {
        self.updateProgress(value: 0.0, notify: notify)
    }
    
    private func updateProgress(value: Float, task: DEUploadTask? = nil, notify: Bool = true) {
        guard  isCurrentTask(task) else {
            return
        }
        
        self.progress = value
        if notify, let progressCallback = self.onDidChangeProgress {
            progressCallback(value)
        }
    }
}


/**
 * Under development.
 */
public class DEDebueExtensionItemUploader: DEExtensionItemUploading {
    
    public struct TaskHandleConfig {
        
        var duration: TimeInterval = 3.0
        var targerProgress: Float = 1.0
        var progressUpdatesCallsCount = 10
        var success: Bool = true
        var error: Error? = nil
        
        public var progressStep: Float {
            return targerProgress / Float(progressUpdatesCallsCount)
        }
        
        public var progressCallRepeatInterval: TimeInterval {
            return duration / Double(progressUpdatesCallsCount)
        }
        
        public init() {
            
        }
    }
    
    public var nextTaskHandleConfig = TaskHandleConfig.init()
    
    public init() {
        
    }
    
    /// Starts uploading task. Returns *false* and does nothing if any task is already performing.
    @discardableResult
    public func upload(task: DEUploadTask) -> Bool {
        guard !self.isUploading else { return false }
        
        return true
    }

    /// Callback for notifying about finishing current task.
    public var onDidChangeProgress: ((Float) -> ())?

    /// Callback for notifying about finishing current task.
    public var onDidFinish: ((Bool, Error?) -> ())?

    /// Value from 0.0 to 1.0, describing current task progress. 0.0 if no task in progress.
    public var progress: Float = 0.0

    public private(set) var isUploading: Bool = false

    private func peformTask(_ task: DEUploadTask) {
        
    }
}
