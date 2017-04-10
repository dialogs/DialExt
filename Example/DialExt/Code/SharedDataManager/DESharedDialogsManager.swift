//
//  DESharedDialogsManager.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 15/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public enum DialogsError: Error {
    
}

public enum UpdateReason: Int {
    case order
    case content
    case other
}

/**
 * Class providing data in prepared state for using.
 * Won't work untill you call start() method.
 */
final public class DESharedDialogsManager {
    
    public enum DialogsState {
        case idle
        case loading
        case loaded
        case failed(Error?)
        
        public var isLoading: Bool {
            switch self {
            case .loading: return true
            default: return false
            }
        }
    }
    
    public let container: DEGroupContainer
    
    public private(set) var context: AppSharedDialogListContext? = nil
    
    public private(set) var dialogIds: [Int64] = []
    
    public private(set) var dialogsState: DialogsState = .idle {
        didSet {
            self.onDidChangeDialogsState?(dialogsState)
        }
    }
    
    public var onDidChangeDialogsState:((DialogsState)->())? = nil
    
    public convenience init(groupContainerId: String, keychainGroup: String) {
        let container = DEGroupContainer.init(groupId:groupContainerId)
        self.init(groupContainer: container, keychainGroup: keychainGroup)
    }
    
    public init(groupContainer: DEGroupContainer, keychainGroup: String) {
        self.container = groupContainer
        self.keychainDataGroup = keychainGroup
    }
    
    public func start() {
        self.resetConfig()
        self.reloadDialogListContext()
    }
    
    public func save(list: AppSharedDialogList, context: AppSharedDialogListContext, completion:((Bool, Error?) -> ())?) {
        guard let config = self.config else {
            return
        }
        config.dataLoader.store(list: list, context: context, handler: completion)
    }
    
    public func saveData(_ data: Data, item: DEGroupContainerItem, completion: ((Bool, Error?) -> ())?) {
        item.writeData(data) { [weak self] (success, error) in
            withExtendedLifetime(self, {
                guard self != nil else { return }
                
                completion?(success, error)
            })
        }
    }
    
    public func reloadDialogListContext() {
        guard !self.dialogsState.isLoading else {
            return
        }
        
        guard let config = self.config else {
            return
        }
        
        self.dialogsState = .loading
        
        config.dataLoader.start()
    }
    
    private func resetConfig() {
        let config = Config.init(container: self.container)
        config.dataLoader.onDidChangeState = { [weak self] state in
            withExtendedLifetime(self, {
                self?.handleChangeDataState(state)
            })
        }
        
        self.config = config
    }
    
    private func handleChangeDataState(_ state: DESharedDialogsDataLoader.DataState) {
        switch state {
        case let .failured(error): handleLoadingFailure(error)
        case let .loaded(context):
            self.context = context
            self.dialogsState = .loaded
        case .idle: break
        }
    }
    
    private func handleLoadingFailure(_ error:Error?) {
        print("Error occured: \(error)")
        
        self.dialogsState = .failed(error)
    }
    
    private let keychainDataGroup: String
    
    private class Config {
        
        let dialogsContextFileItem: DEGroupContainerItem
        let dialogListFileItem: DEGroupContainerItem
        
        let dataLoader: DESharedDialogsDataLoader
        
        init(container: DEGroupContainer) {
            self.dialogsContextFileItem = container.item(forFileNamed: "dialogs")
            self.dialogListFileItem = container.item(forFileNamed: "dialogs_list")
            
            self.dataLoader = DESharedDialogsDataLoader.init(contextFile: self.dialogsContextFileItem,
                                                             listFile: self.dialogListFileItem)
        }
    }
    
    private var config: Config? = nil
    
    private func handleUnfixableFailure(_ error: Error?) {
        fatalError("Could not neither read, neither write to group container. Please, check entitlement. \(error)")
    }
}
