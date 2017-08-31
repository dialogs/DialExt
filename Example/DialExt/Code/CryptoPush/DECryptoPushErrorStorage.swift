//
//  DECryptoPushErrorStorage.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 27/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation


public protocol DECryptoPushErrorStorage {
    
    func setCryptoPushErrorDescription(_ description: String) throws
    
    func getCryptoPushErrorDescription() throws -> String
    
    func resetCryptoPushErrorDescription() throws
    
}

extension DEGroupedKeychainDataProvider: DECryptoPushErrorStorage {
    
    public func getCryptoPushErrorDescription() throws -> String {
        let data = try self.readData(query: DEKeychainQuery.init(access: .cryptoPushErrorAccess(group: nil),
                                                                 operation: .read(config: nil)))
        let string = String.init(data: data, encoding: .utf8)!
        return string
    }
    
    public func resetCryptoPushErrorDescription() throws {
        try self.delete(query: DEKeychainQuery.init(access: .cryptoPushErrorAccess(group: nil), operation: .delete))
    }
    
    public func setCryptoPushErrorDescription(_ description: String) throws {
        let data = description.data(using: .utf8)!
        let query = DEKeychainQuery(access: .cryptoPushErrorAccess(group: self.groupId),
                                    operation: .update(value: data as NSData))
        try self.addOrUpdateData(query: query)
    }
    
}

internal extension DEKeychainQuery.Service {
    internal static let cryptoPushError = DEKeychainQuery.Service.init("im.dlg.crypto.alert-error")
}

internal extension DEKeychainQuery.Access {
    
    internal static let cryptoPushErrorDefaultAccount = "im.dlg.shared"
    
    internal static func cryptoPushErrorAccess(group: String?) -> DEKeychainQuery.Access {
        return self.init(.cryptoPushError, account: DEKeychainQuery.Access.cryptoPushErrorDefaultAccount, group: group)
    }
}
