//
//  DESharedDialogsDataLoader.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 05/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

import ProtocolBuffers

final public class DESharedDialogsDataLoader {
    
    public enum DataState {
        case idle
        case failured(Error?)
        case loaded(AppSharedDialogListContext)
        
        public var dialogs: [AppSharedDialog]? {
            switch self {
            case .loaded(let ctx): return ctx.dialogs
            default: return nil
            }
        }
        
    }
    
    public var state: DataState {
        return composer.state
    }
    
    
    public let listQueuer: DEGroupContainerItemBindedRepresenterQueuer<AppSharedDialogList>
    
    public let contextQueuer: DEGroupContainerItemBindedRepresenterQueuer<AppSharedDialogListContext>
    
    
    public var list: AppSharedDialogList? {
        return listRepresenter.representation
    }
    
    public var context: AppSharedDialogListContext? {
        return contextRepresenter.representation
    }
    
    public private(set) var started: Bool = false
    
    public var overwriteOnFail: Bool = false
    
    public var onDidChangeState: ((DataState) -> ())?
    
    public init(contextFile: DEGroupContainerItem, listFile: DEGroupContainerItem) {
        listRepresenter = AppSharedDialogListBindedRepresenter.init(item: listFile)
        listRepresenter.logOperationDuration = true
        listRepresenter.name = "Shared.DialogIdsList"
        listQueuer = listRepresenter.createQueuer()
        
        contextRepresenter = AppSharedDialogListContextBindedRepresenter.init(item: contextFile)
        contextRepresenter.logOperationDuration = true
        contextRepresenter.name = "Shared.DialogContext"
        contextQueuer = contextRepresenter.createQueuer()
    }
    
    public func start() {
        guard !self.started else {
            return
        }
        
        self.started = true
        
        composer.onDidChangeState = { [unowned self] state in
            self.handleComposerStateChange(state: state)
        }
        
        listRepresenter.onDidChangeRepresentation = { [weak self] list, reason in
            withExtendedLifetime(self, {
                switch reason {
                case .storeSuccess: self?.listQueuer.tryPutNextItem()
                default: break
                }
                self?.composer.list = list
            })
        }
        listRepresenter.onFailToSyncRepresentation = { [weak self] error in
            withExtendedLifetime(self, {
                self?.handleListRepresentationFailure(error: error)
            })
        }
        
        contextRepresenter.onDidChangeRepresentation = { [weak self] context, reason in
            withExtendedLifetime(self, {
                switch reason {
                case .storeSuccess: self?.contextQueuer.tryPutNextItem()
                default: break
                }
                self?.composer.context = context
            })
        }
        contextRepresenter.onFailToSyncRepresentation = { [weak self] error in
            withExtendedLifetime(self, {
                self?.handleContextRepresentationFailure(error: error)
            })
        }
        
        listRepresenter.bind()
        contextRepresenter.bind()
    }

    
    private let composer = DataComposer.init()
    
    private let contextRepresenter: AppSharedDialogListContextBindedRepresenter
    
    private let listRepresenter: AppSharedDialogListBindedRepresenter
    
    
    private struct StoreComposedResult {
        
        var storedList: AppSharedDialogList? = nil
        
        var storedContext: AppSharedDialogListContext? = nil
        
        var error: Error? = nil
        
        var failed: Bool = false
        
        mutating func setFailed(error: Error?) {
            self.failed = true
            self.error = error
        }
        
        var isStored: Bool {
            return storedList != nil && storedContext != nil
        }
    }
    
    private func handleListRepresentationFailure(error: Error?) {
        if self.shouldResetRepresentationForError(error) {
            self.listRepresenter.representation = AppSharedDialogList.empty
        }
    }
    
    private func handleContextRepresentationFailure(error: Error?) {
        if self.shouldResetRepresentationForError(error) {
            self.contextRepresenter.representation = AppSharedDialogListContext.empty
        }
    }
    
    private func shouldResetRepresentationForError(_ error: Error?) -> Bool {
        guard self.overwriteOnFail else {
            return false
        }
        
        guard let reasonError = error else {
            return true
        }
        
        let cocoaError = reasonError as NSError
        if cocoaError.domain == NSCocoaErrorDomain &&
            (cocoaError.code == NSFileNoSuchFileError || cocoaError.code == NSFileReadNoSuchFileError) {
            return true
        }
        
        return false
    }
    
    private func handleComposerStateChange(state: DataState) {
        switch state {
        case .failured(_): handleComposerStateChange(state: state)
        default: onDidChangeState?(state)
        }
    }
}
