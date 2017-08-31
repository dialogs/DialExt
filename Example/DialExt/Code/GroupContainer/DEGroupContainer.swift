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
        return AppSharedDialogList.create { (list) in
            list.ids = self.context.users.map({ Int64($0.id)})
        }
    }
    
    public init() {
        
        let user: AppSharedUser = {
            return AppSharedUser.create({
                $0.id = 123456
                $0.name = "Debug User"
            })
        }()
        
        let privateDialog: AppSharedDialog = {
            return AppSharedDialog.create({
                $0.id = 1234567890
                $0.isGroup = false
                $0.title = "Debug Private Dialog"
                $0.uids = [user.id]
                $0.isReadOnly = false
                $0.accessHash = 909080807070
            })
        }()
        
        let groupDialog: AppSharedDialog = {
            return AppSharedDialog.create({
                $0.id = 1234567891
                $0.isGroup = false
                $0.title = "Debug Group Diaog"
                $0.uids = [user.id]
                $0.isReadOnly = false
                $0.accessHash = 10102020303
            })
        }()
        
        let context: AppSharedDialogListContext = {
            return AppSharedDialogListContext.create({
                $0.dialogs = [privateDialog, groupDialog]
                $0.users = [user]
                $0.version = "1.0.0"
            })
        }()
        
        self.context = context
    }
    
    public func item(forFileNamed name: String, callbackQueue: DispatchQueue) -> DEGroupContainerItem {
        switch name {
        case "dialogs":
            return DEDebugContainerItem.init(data: try! self.context.toJSON())
        case "dialog_list":
            return DEDebugContainerItem.init(data: try! self.list.toJSON())
        default:
            return DEDebugContainerItem.init(data: Data.init())
        }
    }
}
