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
    
    func authIdToData() -> NSData {
        let data = NSMutableData.init()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(self, forKey: "auth_id")
        archiver.finishEncoding()
        return data.copy() as! NSData
    }
    
    static func authIdFromData(_ data: Data) -> DEAuthId {
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
    
    public func provideToken() throws -> String? {
        let data = try self.readData(query: .readShared(.tokenService))
        return String(data: data, encoding: String.Encoding.unicode)
    }
    
    public func writeAuth(_ auth: DEQueryAuth) throws {
        try auth.write(writer: self)
    }
}

public extension DEKeychainQuery.Service {
    public static let authIdService =  DEKeychainQuery.Service.init("auth_id")
    public static let signedIdAuthIdService = DEKeychainQuery.Service("signed_auth_id")
    public static let tokenService = DEKeychainQuery.Service("token")
}
