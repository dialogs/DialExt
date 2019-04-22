//
//  DEGroupedKeychainDataProvider.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 20/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

/**
 This instance using for binding with keychain and replace queries group ids
 (so you create an instance once and perform queries without passing group id).
 */
public class DEGroupedKeychainDataProvider: DEKeychainQueryPerformerable {
    
    public let defaultAuthPolicy: DEUploadAuthPolicy
    
    public let groupId: String
    
    public let provider: DEKeychainQueryPerformerable
    
    public init(groupId: String, keychainProvider: DEKeychainQueryPerformerable, defaultAuthPolicy: DEUploadAuthPolicy) {
        self.groupId = groupId
        self.provider = keychainProvider
        self.defaultAuthPolicy = defaultAuthPolicy
    }
    
    public convenience init(groupId: String, keychainProvider: DEKeychainQueryPerformerable) {
        self.init(groupId: groupId, keychainProvider: keychainProvider, defaultAuthPolicy: .signedAuthId)
    }
    
    public func perform(query: DEKeychainQuery) -> DEKeychainQueryResult {
        var groupedQuery = query
        groupedQuery.access.group = self.groupId
        return self.provider.perform(query: groupedQuery)
    }
    
}
