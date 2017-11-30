//
//  ConfigSynchronizer.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 30/11/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public class ConfigSynchronizer {
    
    public static let defaultFileName = "im.dlg.messenger.config"
    
    public typealias Representer = DEProtobufContainerItemBindedRepresenter<MessengerConfig>
    
    public let representer: Representer
    
    public init(groupId: String, fileName: String = ConfigSynchronizer.defaultFileName) {
        let item = DEGroupContainer.init(groupId: groupId).item(forFileNamed: fileName)
        self.representer = Representer.init(item: item)
    }
    
}
