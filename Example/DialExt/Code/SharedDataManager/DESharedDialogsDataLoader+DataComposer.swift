//
//  DESharedDialogsDataLoader+DataComposer.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 07/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

internal extension DESharedDialogsDataLoader {
    
    /**
     * Composes all given data and provides result data state
     * Also creates dialogs' context with sorted dialogs from context and list items.
     */
    internal class DataComposer {
        
        public private(set) var state: DataState = .idle
        
        public var onDidChangeState:((DataState) -> ())? = nil
        
        var list: AppSharedDialogList? = nil {
            didSet {
                resetState()
            }
        }
        
        var context: AppSharedDialogListContext? = nil {
            didSet {
                resetState()
            }
        }
        
        init() {
            // do nothing
        }
        
        func resetState(error: Error?) {
            self.state = .failured(error)
            
            onDidChangeState?(state)
        }
        
        private func resetState() {
            if let list = self.list, let context = self.context {
                let context = createOrderedDialogsContext(originalContext: context, list: list)
                self.state = .loaded(context)
                
                onDidChangeState?(self.state)
            }
        }
        
        private func createOrderedDialogsContext(originalContext: AppSharedDialogListContext,
                                                 list: AppSharedDialogList) -> AppSharedDialogListContext {
            let filteredSortedDialogs: [AppSharedDialog] = list.ids.flatMap { (dialogId) in
                return originalContext.dialogs.first(where: { $0.id == dialogId})
            }
            
            let updatableContext = originalContext.getBuilder()
            updatableContext.dialogs = filteredSortedDialogs
            return try! updatableContext.build()
        }
    }
}
