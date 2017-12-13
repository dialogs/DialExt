//
//  DEGroupLogger.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 13/12/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public func DEGroupLog(_ string: String) {
    if let logger = DEGroupLogger.shared {
        logger.log(string)
    }
}

public final class DEGroupLogger {
    
    public static private(set) var shared: DEGroupLogger!
    
    public static func setupSharedLogger(keychainGroup: String) {
        let logger = DEGroupLogger.init(keychainGroup: keychainGroup)
        self.shared = logger
    }
    
    private let storage: DECryptoStorage
    
    init(keychainGroup: String) {
        self.storage = DEKeychainDataProvider.init().cryptoStorage(groupId: keychainGroup)
    }
    
    public func log(_ string: String) {
        do {
            try self.storage.appendLogs(string)
        }
        catch {
            DESLog("Log writing failed")
        }
        
    }
    
}
