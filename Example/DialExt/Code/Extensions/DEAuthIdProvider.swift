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

extension DEGroupedKeychainDataProvider: DEWriteableUploadAuthProviding {
    
    public func provideAuthId() throws -> DEAuthId {
        let data = try self.readData(query: .readShared(.authIdService))
        let id = DEAuthId.authIdFromData(data)
        return id
    }
    
    public func provideSignedAuthId() throws -> Data {
        let data = try self.readData(query: .readShared(.signedIdAuthIdService))
        return data
    }
    
    public func writeAuth(_ auth: DEUploadAuth) throws {
        let idData = auth.authId.authIdToData() as NSData
        try self.addOrUpdateData(query: .writeShared(.authIdService, data: idData))
        
        let signedData = auth.signedAuthId as NSData
        try self.addOrUpdateData(query: .writeShared(.signedIdAuthIdService, data: signedData))
    }
}

public extension DEKeychainQuery.Service {
    public static let authIdService =  DEKeychainQuery.Service.init("auth_id")
    public static let signedIdAuthIdService = DEKeychainQuery.Service("signed_auth_id")
}
