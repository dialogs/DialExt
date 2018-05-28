//
//  RequiredUpdateInfoStorage.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 28/05/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation

public protocol RequiredUpdateStorageReadable {
    
    /// Reads RequiredUpdate from storage if find any.
    func readReqUpdateInfo() throws -> ReqUpdate?
    
}

public protocol RequiredUpdateStorageWriteable {
    
    /// Writes RequiredUpdate to storage
    func writeReqUpdateInfo(_ info: ReqUpdate) throws
    
}

/// Default implementation or reading/writing required updates. Based on keychain storage.
public final class RequiredUpdateKeychainStorage: RequiredUpdateStorageReadable, RequiredUpdateStorageWriteable {
    
    private let keychain: DEKeychainQueryPerformerable
    
    public init(keychain: DEKeychainQueryPerformerable) {
        self.keychain = keychain
    }
    
    public func readReqUpdateInfo() throws -> ReqUpdate? {
        
        let data = try self.keychain.readNullableData(query: DEKeychainQuery.init(access: .reqUpdateAccess,
                                                                              operation: .read(config: nil)))
        guard let reqUpdateData = data else {
            return nil
        }
        
        let update = try ReqUpdate.parseFrom(data: reqUpdateData)
        return update
    }
    
    public func writeReqUpdateInfo(_ info: ReqUpdate) throws {
        let data = info.data()
        try self.keychain.rewrite(addQuery: .init(access: .reqUpdateAccess, operation: .add(value: data as NSData)))
    }
    
}


fileprivate let reqUpdateDefaultAccount = "im.dlg.shared.req_update"

fileprivate extension DEKeychainQuery.Access {
    
    static let reqUpdateAccess = DEKeychainQuery.Access.init(DEKeychainQuery.Service.init("ReqUpdate"),
                                                             account: reqUpdateDefaultAccount)
}
