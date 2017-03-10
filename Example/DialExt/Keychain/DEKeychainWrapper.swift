//
//  DEKeychainWrapper.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 10/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

/**
 * Class that simplifies work with keychain almost to the level of Dictionary. Thread-safe.
 */
public class DEKeychainWrapper {
    
    
    /// Creates new instance which works with keychain area shared with another apps
    ///
    /// - Parameters:
    ///   - group: Name of the area shared with another apps
    ///   - account: Account name
    /// - Returns: New instance of DEKeychainWrapper
    public class func createSharedGroupKeychainWrapper(group: String,
                                                       account: String) -> DEKeychainWrapper {
        return DEKeychainWrapper.init(dataProvider: KeychainDataProvider.init(),
                                      account: account,
                                      group: group)
    }
    
    let dataProvider: DEKeychainQueryPerformerable
    
    let account: String

    let group: String?
    
    public var hasGroup: Bool {
        return group != nil
    }
    
    public init(dataProvider: DEKeychainQueryPerformerable, account: String, group: String? ) {
        self.dataProvider = dataProvider
        self.account = account
        self.group = group
    }
    
    public func value(for key: String) -> DEKeychainQueryResult {
        let access = DEKeychainQuery.Access(service: key, account: self.account, group: self.group)
        let operation = DEKeychainQuery.Operation.read(config: nil)
        let query = DEKeychainQuery(access: access, operation: operation)
        
        return dataProvider.perform(query: query)
    }
    
    public func setValue(value: AnyObject, for key: String) -> DEKeychainQueryResult {
        let access = DEKeychainQuery.Access(service: key, account: self.account, group: self.group)
        let operation = DEKeychainQuery.Operation.update(value: value)
        let query = DEKeychainQuery(access: access, operation: operation)
        
        return dataProvider.perform(query: query)
    }
}


