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

    public let container: DEGroupContainer
    
    public var dataLoader: DESharedDialogsDataLoader {
        return self.config.dataLoader
    }
    
    public convenience init(groupContainerId: String, keychainGroup: String) {
        let container = DEGroupContainer.init(groupId:groupContainerId)
        self.init(groupContainer: container, keychainGroup: keychainGroup)
    }
    
    public init(groupContainer: DEGroupContainer, keychainGroup: String) {
        self.container = groupContainer
        self.keychainDataGroup = keychainGroup
        self.config = Config.init(container: self.container)
    }

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
    
    private let config: Config
    
    private let keychainDataGroup: String
}
