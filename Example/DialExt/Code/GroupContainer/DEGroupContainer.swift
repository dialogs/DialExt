//
//  DEGroupContainer.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 10/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public protocol DEGroupContainerable {
    
    var groupId: String { get }
    
    func item(forFileNamed name: String, callbackQueue: DispatchQueue) -> DEGroupContainerItem
}

extension DEGroupContainerable {
    
    func item(forFileNamed name: String) -> DEGroupContainerItem {
        return self.item(forFileNamed: name, callbackQueue: .main)
    }
    
    func dialogsContextItem(callbackQueue: DispatchQueue = .main) -> DEGroupContainerItem {
        return self.item(forFileNamed: "dialogs", callbackQueue: callbackQueue)
    }
    
    func dialogListFileItem(callbackQueue: DispatchQueue = .main) -> DEGroupContainerItem {
        return self.item(forFileNamed: "dialog_list", callbackQueue: callbackQueue)
    }
}


public class DEGroupContainer: DEGroupContainerable {
    
    public let groupId: String
    
    private lazy var containerUrl: URL = {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: self.groupId) else {
            fatalError("Could not find container for group '\(self.groupId)'. Please, check your entitlements.")
        }
        return url
    }()
    
    public init(groupId: String) {
        self.groupId = groupId
    }
    
    public func item(forFileNamed name: String, callbackQueue: DispatchQueue) -> DEGroupContainerItem {
        let fileUrl = self.containerUrl.appendingPathComponent(name)
        let presenter = DEGroupContainerFilePresenter.init(url: fileUrl, callbackQueue: callbackQueue)
        return presenter
    }
    
}


public class DEDebugContainer: DEGroupContainerable {
    
    public var groupId: String = ""
    
    private let context: AppSharedDialogListContext
    
    private var list: AppSharedDialogList {
        let builder = AppSharedDialogList.getBuilder()
        builder.ids = self.context.users.map({ Int64($0.id)})
        return try! builder.build()
    }
    
    public init() {
        
        let user: AppSharedUser = {
            let builder = AppSharedUser.getBuilder()
            builder.id = 123456
            builder.name = "Debug User"
            return try! builder.build()
        }()
        
        let privateDialog: AppSharedDialog = {
            let builder = AppSharedDialog.getBuilder()
            builder.id = 1234567890
            builder.isGroup = false
            builder.title = "Debug Private Dialog"
            builder.uids = [user.id]
            builder.isReadOnly = false
            builder.accessHash = 909080807070
            return try! builder.build()
        }()
        
        let groupDialog: AppSharedDialog = {
            let builder = AppSharedDialog.getBuilder()
            builder.id = 1234567891
            builder.isGroup = false
            builder.title = "Debug Group Diaog"
            builder.uids = [user.id]
            builder.isReadOnly = false
            builder.accessHash = 10102020303
            return try! builder.build()
        }()
        
        let context: AppSharedDialogListContext = {
            let builder = AppSharedDialogListContext.getBuilder()
            builder.dialogs = [privateDialog, groupDialog]
            builder.users = [user]
            builder.version = "1.0.0"
            return try! builder.build()
        }()
        
        self.context = context
    }
    
    public func item(forFileNamed name: String, callbackQueue: DispatchQueue) -> DEGroupContainerItem {
        switch name {
        case "dialogs":
            return DEDebugContainerItem.init(data: self.context.data())
        case "dialog_list":
            return DEDebugContainerItem.init(data: self.list.data())
        default:
            return DEDebugContainerItem.init(data: Data.init())
        }
    }
}
