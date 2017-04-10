//
//  DESharedDialogsDataLoader.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 05/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit


final public class DESharedDialogsDataLoader {
    
    public enum DataState {
        case idle
        case failured(Error?)
        case loaded(AppSharedDialogListContext)
    }
    
    public var state: DataState {
        return composer.state
    }
    
    public var overwriteOnFail: Bool = false
    
    public var onDidChangeState: ((DataState) -> ())?
    
    public init(contextFile: DEGroupContainerItem, listFile: DEGroupContainerItem) {
        listRepresenter = AppSharedDialogListRepresenter.init(item: listFile)
        contextRepresenter = AppSharedDialogListContextItemRepresenter.init(item: contextFile)
    }
    
    public func start() {
        composer.onDidChangeState = { [unowned self] state in
            self.handleComposerStateChange(state: state)
        }
        
        listRepresenter.startObserving { [weak self] (result, _) in
            withExtendedLifetime(self, {
                switch result {
                case let .success(list): self?.composer.list = list
                case let .failure(error): self?.composer.resetState(error: error)
                }
            })
        }
        
        contextRepresenter.startObserving { [weak self] (result, _) in
            withExtendedLifetime(self, {
                switch result {
                case let .success(context): self?.composer.context = context
                case let .failure(error): self?.composer.resetState(error: error)
                }
            })
        }
    }
    
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
    
    public func store(list: AppSharedDialogList,
                      context: AppSharedDialogListContext,
                      handler: ((Bool, Error?) -> ())?) {
        
        let group = DispatchGroup.init()
        
        var composedResult = StoreComposedResult()
        
        group.enter()
        listRepresenter.store(representation: list) { (result) in
            switch result {
            case let .failure(error): composedResult.setFailed(error: error)
            case .success(_): composedResult.storedList = list
            }
            group.leave()
        }
        
        group.enter()
        contextRepresenter.store(representation: context) { (result) in
            switch result {
            case let .failure(error): composedResult.setFailed(error: error)
            case .success(_): composedResult.storedContext = context
            }
            group.leave()
        }
        
        group.notify(queue: .main) { 
            handler?(!composedResult.failed, composedResult.error)
        }
    }
    
    private func handleComposerStateChange(state: DataState) {
        switch state {
        case .failured(_):
            if overwriteOnFail {
                self.resetRepresentations()
            }
            handleComposerStateChange(state: state)

        default: onDidChangeState?(state)
        }
    }
    
    private func resetRepresentations() {
        listRepresenter.store(representation: AppSharedDialogList.empty)
        contextRepresenter.store(representation: AppSharedDialogListContext.empty)
    }
    
    private let composer = DataComposer.init()
    
    private let contextRepresenter: AppSharedDialogListContextItemRepresenter
    
    private let listRepresenter: AppSharedDialogListRepresenter
    
}
