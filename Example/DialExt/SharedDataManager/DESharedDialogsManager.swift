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

/**
 * Class providing data in prepared state for using.
 * Won't work untill you call start() method.
 *
 */
public class DESharedDialogsManager {
    
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
    
    private let container: DEGroupContainer
    
    private let keychainDataGroup: String
    
    private var dialogsFileItem: DEGroupContainerItem? = nil
    
    public private(set) var context: AppSharedDialogListContext? = nil
    
    public private(set) var dialogsState: DialogsState = .idle {
        didSet {
            self.onDidChangeDialogsState?(dialogsState)
        }
    }
    
    public var onDidChangeDialogsState:((DialogsState)->())? = nil
    
    public init(groupContainerId: String, keychainGroup: String) {
        self.container = DEGroupContainer.init(groupId:groupContainerId)
        self.keychainDataGroup = keychainGroup
    }
    
    public func start() {
        self.dialogsFileItem = container.item(forFileNamed: "dialogs")
        self.reloadDialogListContext()
    }
    
    public func saveDialogListContext(_ context: AppSharedDialogListContext, completion:((Bool, Error?) -> ())?) {
        let data = context.data()
        dialogsFileItem!.writeData(data) { [weak self] (success, error) in
            withExtendedLifetime(self, {
                guard self != nil else { return }
                
                if success {
                    self!.context = context
                    self!.dialogsState = .loaded
                }
                
                completion?(success, error)
            })
        }
    }
    
    public func reloadDialogListContext() {
        guard !self.dialogsState.isLoading else {
            return
        }
        
        guard let item = self.dialogsFileItem else {
            fatalError("File item is not prepared!")
        }
        
        self.dialogsState = .loading
        item.readData({ [weak self] (data) in
            withExtendedLifetime(self, {
                guard self != nil else { return }
                self!.handleLoadedData(data)
            })
        }) { [weak self] (error) in
            withExtendedLifetime(self, {
                guard self != nil else { return }
                self!.handleLoadingFailure(error)
            })
        }
    }
    
    private func handleLoadingFailure(_ error:Error?) {
        let emptyContext = AppSharedDialogListContext.createEmptyContext()
        saveDialogListContext(emptyContext, completion: { [weak self] success, error in
            guard success else {
                self!.handleUnfixableFailure(error)
                return
            }
        })
        let data = emptyContext.data()
        dialogsFileItem!.writeData(data) { [weak self] (success, error) in
            withExtendedLifetime(self, {
                guard self != nil else { return }
                if success {
                    self!.context = emptyContext
                    self!.dialogsState = .loaded
                }
                else {
                    self!.handleUnfixableFailure(error)
                }
            })
        }
        self.dialogsState = .failed(error)
    }
    
    private func handleUnfixableFailure(_ error: Error?) {
        fatalError("Could not neither read, neither write to group container. Please, check entitlement. \(error)")
    }
    
    private func handleLoadedData(_ loadedData: Data?) {
        guard let data = loadedData else {
            self.setupEmptyContext()
            return
        }
        
        do {
            self.context = try AppSharedDialogListContext.parseFrom(data: data)
            self.dialogsState = .loaded
        }
        catch {
            self.setupEmptyContext(resetState: false)
            self.dialogsState = .failed(error)
        }
    }
    
    private func setupEmptyContext(resetState:Bool = true) {
        self.context = AppSharedDialogListContext.createEmptyContext()
        if resetState {
            self.dialogsState = .loaded
        }
    }
}
