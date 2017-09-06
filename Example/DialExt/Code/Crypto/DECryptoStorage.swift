//
//  DECryptoStorage.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 20/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import DLGSodium

/**
 DECryptoStorage provides access to security storage to keep sensitive data needed for messages encryption/decription
 
 It's intented that implementer is **thread-safe**.
 */
public protocol DECryptoStorageReadable {
    
    func cryptoSharedSecret() throws -> DESharedSecret?
    
    func cryptoMessgingNonce() throws -> DEInt64BasedNonce?
}


public protocol DECryptoStorageWriteable {
    
    /// Sets new messaging data
    func setCryptoSharedSecret(_ messaing: DESharedSecret) throws
    
    func setCryptoMessagingNonce(_ nonce: DEInt64BasedNonce) throws
    
    /// Clears all data
    func resetCryptoStorage() throws
}

public typealias DECryptoStorage = DECryptoStorageReadable & DECryptoStorageWriteable


extension DEGroupedKeychainDataProvider: DECryptoStorageWriteable, DECryptoStorageReadable {
    
    public func setCryptoSharedSecret(_ secret: DESharedSecret) throws {
        let data = secret.protobufSharedSecret.data()
        try self.addOrUpdateData(query: .writeCryptoItemQuery(service: .sharedSecret, data: data as NSData))
    }
    
    public func cryptoSharedSecret() throws -> DESharedSecret? {
        
        let data: Data
        do {
            if let storedData = try self.readNullableData(query: .readCryptoItemQuery(service: .sharedSecret)) {
                data = storedData
            }
            else {
                return nil
            }
        }
        
        let protoSecret = try SharedSecret.parseFrom(data: data)
        let secret = DESharedSecret.init(protobufSharedSecret: protoSecret)
        return secret
    }
    
    public func setCryptoMessagingNonce(_ nonce: DEInt64BasedNonce) throws {
        let data = nonce.nonce as NSData
        try self.addOrUpdateData(query: .writeCryptoItemQuery(service: .messagingNonce, data: data))
    }
    
    public func cryptoMessgingNonce() throws -> DEInt64BasedNonce? {
        let storedData = try self.readNullableData(query: .readCryptoItemQuery(service: .messagingNonce))
        guard let data = storedData else {
            return nil
        }
        let nonce = DEInt64BasedNonce.init(data: data)
        return nonce
    }
    
    public func resetCryptoStorage() throws {
        let itemsToDelete: [DEKeychainQuery.Access.CryptoService] = [
            DEKeychainQuery.Access.CryptoService.sharedSecret,
            DEKeychainQuery.Access.CryptoService.messagingNonce
        ]
        
        itemsToDelete.forEach { (service) in
            do {
                try self.delete(query: DEKeychainQuery.deleteCryptoItemQuery(service: service))
            }
            catch {
                DESLog("Fail to delete crypto item", tag: "CRYPTO")
            }
        }
    }
    
}

public extension DEKeychainDataProvider {
    
    public func cryptoStorage(groupId: String) -> DECryptoStorage {
        return DEGroupedKeychainDataProvider.init(groupId: groupId, keychainProvider: self)
    }
    
}


internal extension DEKeychainQuery.Service {
    
    internal static let cryptoMessagingKey = DEKeychainQuery.Service.init("im.dlg.crypto.messaging")
    internal static let cryptoSharedSecret = DEKeychainQuery.Service.init("im.dlg.crypto.shared_secret")
    
}


internal extension DEKeychainQuery.Access {
    
    internal enum CryptoService {
        
        case messagingNonce
        
        case sharedSecret
        
        var service: DEKeychainQuery.Service {
            switch self {
            case .messagingNonce: return .cryptoMessagingKey
            case .sharedSecret: return .cryptoSharedSecret
            }
        }
    }
    
    private static let cryptoServiceDefaultAccount = "im.dlg.shared"
    
    internal static func cryptoItem(service: CryptoService) -> DEKeychainQuery.Access {
        return self.init(service.service, account: cryptoServiceDefaultAccount)
    }
}

internal extension DEKeychainQuery {
    
    internal static func readCryptoItemQuery(service: DEKeychainQuery.Access.CryptoService) -> DEKeychainQuery {
        return self.init(access: .cryptoItem(service: service), operation: .read(config: nil))
    }
    
    internal static func writeCryptoItemQuery(service: DEKeychainQuery.Access.CryptoService, data: NSData) -> DEKeychainQuery {
        var query = self.init(access: .cryptoItem(service: service), operation: .add(value: data))
        query.synchronizable = Synchronizable.no(.always)
        return query
    }
    
    internal static func deleteCryptoItemQuery(service: DEKeychainQuery.Access.CryptoService) -> DEKeychainQuery {
        return self.init(access: .cryptoItem(service: service), operation: .delete)
    }
}
