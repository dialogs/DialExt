//
//  DEAuthIdProvider.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 28/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public typealias DEAuthId = Int64

extension DEAuthId {
    
    fileprivate func authIdToData() -> NSData {
        let data = NSMutableData.init()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(self, forKey: "auth_id")
        archiver.finishEncoding()
        return data.copy() as! NSData
    }
    
    fileprivate static func authIdFromData(_ data: Data) -> DEAuthId {
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        let authId = unarchiver.decodeInt64(forKey: "auth_id")
        unarchiver.finishDecoding()
        return authId
    }
}

public extension DEKeychainDataProvider {
    
    func setAuthId(_ id: DEAuthId, groupId: String) throws {
        let query = DEKeychainQuery.authIdWriteQuery(id: id, groupId: groupId)
        let result = self.performAddOrUpdate(query: query)
        
        if case let DEKeychainQueryResult.failure(status: status) = result {
            let code = Int(status!)
            throw NSError(domain: NSOSStatusErrorDomain, code: code, userInfo: nil)

        }
    }
    
    func authId(groupId: String) throws -> DEAuthId {
        let query = DEKeychainQuery.authIdReadQuery(groupId: groupId)
        let result = self.perform(query: query)
        switch result {
        case let .failure(status: status):
            let code = Int(status!)
            throw NSError(domain: NSOSStatusErrorDomain, code: code, userInfo: nil)
        case let .success(values: values):
            let data = values!.first! as! Data
            let id = DEAuthId.authIdFromData(data)
            return id
        }
    }
}


public extension DEKeychainQuery.Access {
    
    public static let defaultAuthIdService = "auth_id"
    
    public static let defaultAuthIdAccount = "im.dlg.shared"
    
    public static func createAuthIdAccess(groupId: String) -> DEKeychainQuery.Access {
        return DEKeychainQuery.Access(service: defaultAuthIdService, account: defaultAuthIdAccount, group: groupId)
    }
    
}


public extension DEKeychainQuery {
    
    public static func authIdReadQuery(groupId: String) -> DEKeychainQuery {
        let access = DEKeychainQuery.Access.createAuthIdAccess(groupId: groupId)
        let operation = DEKeychainQuery.Operation.read(config: nil)
        return self.init(access: access, operation: operation)
    }
    
    public static func authIdWriteQuery(data: NSData, groupId: String) -> DEKeychainQuery {
        let access = DEKeychainQuery.Access.createAuthIdAccess(groupId: groupId)
        let operation = DEKeychainQuery.Operation.add(value: data)
        return self.init(access: access, operation: operation)
    }
    
    public static func authIdWriteQuery(id: DEAuthId, groupId: String) -> DEKeychainQuery {
        return authIdWriteQuery(data: id.authIdToData(), groupId: groupId)
    }
}
