//
//  DEKeychainQuery.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 10/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import Security

public typealias DEKeychainEntriesDictionary = [String : AnyObject]


/**
 * Source item for performing any keychain operation
 */
public struct DEKeychainQuery {
    
    /// Describes access to a value in keychain. You can treat it as a key for value in dictionary.
    public var access: Access
    
    /// Desribes keychain query type and details
    public var operation: Operation
    
    /// Describes entry synchronization and access details
    public var synchronizable: Synchronizable?
    
    public init(access: Access, operation: Operation) {
        self.access = access
        self.operation = operation
    }
    
    /// Describes entry synchronization and access details
    public enum Synchronizable {
        case any                        ///< Used for searching (including searching for deleting).
        case yes(SynchronizableType)    ///< Value shared between user devices.
        case no(ThisDeviceOnlyType)     ///< Value is unique for device.
        
        public enum SynchronizableType {
            case whenUnlocked
            case afterFirstUnlock
            case always
            
            func keychainValue() -> String {
                let string: String
                switch self {
                case .whenUnlocked:
                    string = kSecAttrAccessibleWhenUnlocked as String
                case .afterFirstUnlock:
                    string = kSecAttrAccessibleAfterFirstUnlock as String
                case .always:
                    string = kSecAttrAccessibleAlways as String
                }
                return string
            }
        }
        
        public enum ThisDeviceOnlyType {
            case whenPasscodeSet
            case whenUnlocked
            case afterFirstUnlock
            case always
            
            func keychainValue() -> String {
                let string: String
                switch self {
                case .whenPasscodeSet:
                    string = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly as String
                case .whenUnlocked:
                    string = kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String
                case .afterFirstUnlock:
                    string = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
                case .always:
                    string = kSecAttrAccessibleAlwaysThisDeviceOnly as String
                }
                return string
            }
        }
        
        internal func keychainSynchronizableValue() -> AnyObject {
            let value: AnyObject
            switch self {
            case .any:
                value = kSecAttrSynchronizableAny as AnyObject
            case .yes:
                value = kCFBooleanTrue as AnyObject
            case .no:
                value = kCFBooleanFalse as AnyObject
            }
            return value
        }
        
        internal func keychainAccessibleValue() -> AnyObject? {
            var value: String?
            switch self {
            case let .yes(syncType):
                value = syncType.keychainValue()
            case let .no(unsyncType):
                value = unsyncType.keychainValue()
            default:
                value = nil
            }
            return value as AnyObject?
        }
        
        internal func dictionaryRepresentation() -> DEKeychainEntriesDictionary {
            var representation = [kSecAttrSynchronizable as String : keychainSynchronizableValue()]
            if let accessibleValue = keychainAccessibleValue() {
                representation[kSecAttrAccessible as String] = accessibleValue
            }
            return representation
        }
    }
    
    /// Describes access to a value in keychain. You can treat it as a key for value in dictionary.
    public struct Access {
                
        public let service: DEKeychainQuery.Service
        
        public let account: String
        
        /**
         * Group is for sharing entries between apps.
         * You should set appropriate value in your app entitlements.
         * Otherwise you will get -25243 error if this value is not nil.
         */
        public var group: String?
        
        public func dictionaryRepresentation() -> DEKeychainEntriesDictionary {
            var representation: DEKeychainEntriesDictionary = [:]
            representation[kSecClass as String] = kSecClassGenericPassword
            representation[kSecAttrService as String] = service.rawValue as AnyObject
            representation[kSecAttrAccount as String] = account as AnyObject
            if let group = group {
                representation[kSecAttrAccessGroup as String] = group as AnyObject
            }
            
            return representation
        }
        
        public init(_ service: DEKeychainQuery.Service, account: String, group: String? = nil) {
            self.service = service
            self.account = account
            self.group = group
        }
        
        
    }
    
    /**
     Extend service by declaring you static constants
     */
    public struct Service: Hashable, RawRepresentable {
        
        public typealias RawValue = String
        
        public let rawValue: RawValue
        
        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
        
        public init(_ rawValue: RawValue) {
            self.init(rawValue: rawValue)
        }
        
        public var hashValue: Int {
            return self.rawValue.hashValue
        }
        
        public static func ==(lhs: Service, rhs: Service) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
    }
    
    /// Operation desribes keychain query type and details
    public enum Operation {
        
        public enum Subtype: Int {
            case add
            case update
            case read
            case delete
        }
        
        public var subtype: Subtype {
            switch self {
            case .add(value: _): return .add
            case .delete: return .delete
            case .read(config: _): return .read
            case .update(value: _): return .update
            }
        }
        
        public struct ReadConfig {
            public enum Limit {
                case one
                case all
                
                internal func keychainValue() -> String {
                    let value: String
                    switch self {
                    case .one:
                        value = kSecMatchLimitOne as String
                    case .all:
                        value = kSecMatchLimitAll as String
                    }
                    return value
                }
                
                internal func dictionaryRepresentation() -> DEKeychainEntriesDictionary {
                    return [(kSecMatchLimit as String) : keychainValue() as AnyObject]
                }
            }
            public let limit: Limit?
            
            public var isOneItemExpected: Bool {
                guard let limit = limit else {
                    return true
                }
                return limit == .one
            }
        }
        
        /// Adds data to keychain. Fails if entry already exists.
        case add(value: AnyObject)
        
        /// Updates data in keychain. Failes if entry does not exist.
        case update(value: AnyObject)
        
        /// Reads entry from keychain and returns data. Fails if entry does not exist.
        case read(config: ReadConfig?)
        
        /// Removes entry from keychain. Fails if entry does not exist.
        case delete
        
        // TODO: todo: add 'update' and 'delete'
        internal func writingValueDictionaryRepresentation() -> DEKeychainEntriesDictionary? {
            let attributes: DEKeychainEntriesDictionary?
            switch self {
            case let .add(value: value):
                attributes = [kSecValueData as String : value as AnyObject]
            case let .update(value: value):
                attributes = [kSecValueData as String : value as AnyObject]
            default:
                attributes = nil
            }
            return attributes
        }
    }
    
    func dictionaryRepresentation() -> DEKeychainEntriesDictionary {
        var representation = access.dictionaryRepresentation()
        switch operation {
            
        case .add:
            representation.de_merge(with: operation.writingValueDictionaryRepresentation()!)
            break
            
        case let .read(config: config):
            if let limitRepresentation = config?.limit?.dictionaryRepresentation() {
                representation.de_merge(with: limitRepresentation)
            }
            representation[kSecReturnAttributes as String] = kCFBooleanTrue
            representation[kSecReturnData as String] = kCFBooleanTrue
            
        default:
            break
        }
        
        if let synchronizable = synchronizable {
            representation.de_merge(with: synchronizable.dictionaryRepresentation())
        }
        
        return representation
    }
}
