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

public enum DEKeychainQueryError: Error {
    /// Keychain failed, but there is no os status providen
    case noOSStatus
    
    /// Trying to perform operation with wrong query (like reading with writing operation)
    case wrongQuery
    
    /// Query finished with success, but returns no results.
    case noResults
    
    var isNoResultsError: Bool {
        return self == DEKeychainQueryError.noResults
    }
    
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
    
    func delete(query: DEKeychainQuery, safely: Bool = true) throws {
        guard case .delete = query.operation else {
            throw DEKeychainQueryError.wrongQuery
        }
        
        let result = self.perform(query: query)
        if case let .failure(status: status) = result, status != errSecItemNotFound {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status ?? -1), userInfo: nil)
        }
    }
    
    @discardableResult func readData(access: DEKeychainQuery.Access,
                                     config: DEKeychainQuery.Operation.ReadConfig? = nil ) throws -> Data {
        return try self.readData(query: .init(access: access, operation: .read(config: config)))
    }
    
    @discardableResult func readData(query: DEKeychainQuery) throws -> Data {
        guard query.operation.subtype == .read else {
            throw DEKeychainQueryError.wrongQuery
        }
        let result = self.perform(query: query)
        if result.isItemNotFound {
            throw DEKeychainQueryError.noResults
        }
        try result.doIfFailed { (status) in
            guard let errorCode = status else {
                throw DEKeychainQueryError.noOSStatus
            }
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(errorCode), userInfo: nil)
        }
        
        var data: Data! = nil
        try result.doIfSuccess({ (results) in
            guard let firstResult = results?.first as? NSData else {
                throw DEKeychainQueryError.noResults
            }
            data = firstResult as Data
        })
        return data
    }
    
    @discardableResult func readNullableData(access: DEKeychainQuery.Access,
                                             config: DEKeychainQuery.Operation.ReadConfig? = nil ) throws -> Data? {
        return try self.readNullableData(query: .init(access: access, operation: .read(config: config)))
    }
    
    @discardableResult func readNullableData(query: DEKeychainQuery) throws -> Data? {
        do {
            let data = try self.readData(query: query)
            return data
        }
        catch {
            if let keychainError = error as? DEKeychainQueryError, keychainError.isNoResultsError {
                return nil
            }
            throw error
        }
    }
    
    func addOrUpdateData(query: DEKeychainQuery) throws {
        let result = self.performAddOrUpdate(query: query)
        try result.doIfFailed({ (status) in
            guard let errorCode = status else {
                throw DEKeychainQueryError.noOSStatus
            }
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(errorCode), userInfo: nil)
        })
    }
    
    func addOrUpdateData(access: DEKeychainQuery.Access, data: Data) throws {
        try self.addOrUpdateData(query: .init(access: access, operation: .add(value: data as NSData)))
    }
    
    @discardableResult func performAddOrUpdate(query: DEKeychainQuery) ->  DEKeychainQueryResult {
        let updateQuery: DEKeychainQuery?
        switch query.operation {
        case let .add(value: addingValue):
            var modifableQuery = query
            modifableQuery.operation = .update(value: addingValue)
            updateQuery = modifableQuery
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
    
    public func shared(groupName: String) -> DEGroupedKeychainDataProvider {
        return DEGroupedKeychainDataProvider.init(groupId: groupName, keychainProvider: self)
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
