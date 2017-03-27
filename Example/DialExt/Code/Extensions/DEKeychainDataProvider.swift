//
//  DEKeychainDataProvider.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 10/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public protocol DEKeychainQueryPerformerable {
    @discardableResult func perform(query: DEKeychainQuery) ->  DEKeychainQueryResult
}

public extension DEKeychainQueryPerformerable {
    
    /// Returns 'success' even if deleting item does not exist (which is not keychain native behavior)
    @discardableResult func performSafeDeletion(query: DEKeychainQuery) ->  DEKeychainQueryResult {
        guard case .delete = query.operation else {
            assertionFailure("Unexpected query operation: \(query.operation)")
            return  DEKeychainQueryResult.create(status: errSecBadReq, values: nil)
        }
        var result = self.perform(query: query)
        if case let .failure(status: status) = result, status == errSecItemNotFound {
            result = .success(values: nil)
        }
        return result
    }
    
    @discardableResult func performAddOrUpdate(query: DEKeychainQuery) ->  DEKeychainQueryResult {
        let updateQuery: DEKeychainQuery?
        switch query.operation {
        case let .add(value: addingValue):
            let operation = DEKeychainQuery.Operation.update(value: addingValue)
            updateQuery = DEKeychainQuery.init(access: query.access, operation: operation)
        case .update:
            updateQuery = query
        default:
            assertionFailure("Unexpected query operation: \(query.operation)")
            updateQuery = nil
        }
        
        guard updateQuery != nil else {
            return  DEKeychainQueryResult.create(status: errSecBadReq, values: nil)
        }
        
        var result = self.perform(query: updateQuery!)
        if case let .failure(status: status) = result, status == errSecItemNotFound {
            let addQuery: DEKeychainQuery?
            switch query.operation {
            case .add:
                addQuery = query
            case let .update(value: value):
                let operation = DEKeychainQuery.Operation.add(value: value)
                addQuery = DEKeychainQuery.init(access: query.access, operation: operation)
            default:
                assertionFailure("Unexpected query operation: \(query.operation)")
                addQuery = nil
            }
            guard addQuery != nil else {
                return  DEKeychainQueryResult.create(status: errSecBadReq, values: nil)
            }
            
            result = self.perform(query: addQuery!)
        }
        
        return result
    }
}

public class DEKeychainDataProvider: DEKeychainQueryPerformerable {
    
    public init() {
        
    }
    
    public func perform(query: DEKeychainQuery) ->  DEKeychainQueryResult {
        let representation = query.dictionaryRepresentation()
        let attributes = representation as CFDictionary
        
        let result:  DEKeychainQueryResult
        switch query.operation {
            
        case .add:
            let status = SecItemAdd(attributes, nil)
            result =  DEKeychainQueryResult.create(status: status, values: nil)
            
        case .update:
            let valueToUpdate = query.operation.writingValueDictionaryRepresentation()! as CFDictionary
            let status = SecItemUpdate(attributes, valueToUpdate)
            result =  DEKeychainQueryResult.create(status: status, values: nil)
            
        case let .read(config: config):
            // Try to fetch the existing keychain item that matches the query.
            var queryResult: AnyObject?
            let status = withUnsafeMutablePointer(to: &queryResult) {
                SecItemCopyMatching(attributes, UnsafeMutablePointer($0))
            }
            
            guard status == errSecSuccess else {
                return  DEKeychainQueryResult.create(status: status, values: nil)
            }
            
            let oneItemExpected = config != nil ? config!.isOneItemExpected : true
            let values = executeValues(from: queryResult!, oneItemExpected: oneItemExpected)
            result =  DEKeychainQueryResult.create(status: status, values: values)
            
        case .delete:
            let status = SecItemDelete(attributes)
            result =  DEKeychainQueryResult.create(status: status, values: nil)
        }
        return result
    }
    
    private func executeValues(from queryResult: AnyObject, oneItemExpected: Bool) -> [AnyObject] {
        let values: [AnyObject]
        if oneItemExpected {
            let result = queryResult as! DEKeychainEntriesDictionary
            let value = result[kSecValueData as String] as AnyObject
            values = [value]
        }
        else {
            var mutableValues: [AnyObject] = []
            
            let results = queryResult as! [DEKeychainEntriesDictionary]
            for resultItem in results {
                mutableValues.append(resultItem[kSecValueData as String] as AnyObject)
            }
            
            values = mutableValues
        }
        return values
    }
}
