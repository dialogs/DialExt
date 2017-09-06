//
//   DEKeychainQueryResult.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 10/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import Security

/**
 * Keychain query performing result.
 */
public enum  DEKeychainQueryResult {
    case failure(status: OSStatus?)
    case success(values: [AnyObject]?)
    
    @discardableResult public func doIfSuccess(_ block: ([AnyObject]?) throws -> ()) rethrows -> Bool {
        if case let .success(values: values) = self {
            try block(values)
            return true
        }
        return false
    }
    
    @discardableResult public func doIfFailed(_ block: ((OSStatus?) throws -> ())) rethrows -> Bool {
        if case let .failure(status: status) = self {
            try block(status)
            return true
        }
        return false
    }
    
    /// Is query successfully performed.
    public var isSuccess: Bool {
        if case .success(_) = self {
            return true
        }
        return false
    }
    
    /// Is query failed because of item was not found
    public var isItemNotFound: Bool {
        guard case let .failure(status: status) = self, status != nil else {
            return false
        }
        return status! == errSecItemNotFound
    }
    
    public var isItemDuplicate: Bool {
        guard case let .failure(status: status) = self, status != nil else {
            return false
        }
        return status! == errSecDuplicateItem
    }
    
    /// Is query failed with an error which possibly means you didn't specified Access Group in entitlements.plist
    public var isNoAccessError: Bool {
        guard case let .failure(status: status) = self, status != nil else {
            return false
        }
        
        return status! == OSStatus(-25243)
    }
    
    static func create(status: OSStatus, values: [AnyObject]?) ->  DEKeychainQueryResult {
        let result:  DEKeychainQueryResult
        if status == errSecSuccess {
            result = .success(values: values)
        }
        else {
            result = .failure(status: status)
        }
        return result
    }
}

