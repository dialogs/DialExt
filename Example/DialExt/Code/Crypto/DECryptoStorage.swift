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
    
    func cryptoNonceList() throws -> [DEInt64BasedNonce]?
    
    func cryptoLogs() throws -> String?
}


public protocol DECryptoStorageWriteable: DECryptoStorageReadable {
    
    /// Sets new messaging data
    func setCryptoSharedSecret(_ messaing: DESharedSecret) throws
    
    func setCryptoMessagingNonce(_ nonce: DEInt64BasedNonce) throws
    
    func setCryptoLogs(_ logs: String) throws
    
    func removeCryptoMessagingNonce() throws
    
    func setCryptoNonceList(_ list: [DEInt64BasedNonce]) throws
    
    /// Clears all data
    func resetCryptoStorage() throws
}

public extension DECryptoStorageWriteable {
    
    /**
  Inserts nonce into a nonce list. Removes last nonce if needed.
     Limit is 50.
 */
    func pushNonceToList(_ nonce: DEInt64BasedNonce) throws {
        try self.pushNonceToList(nonce, limit: 50)
    }
    
    /**
     Inserts nonce into a nonce list. Removes last nonce from list if needed.
     Limit should be postive (> 0). Recommended is 50 (you can use 'pushNonceToList' instead).
     */
    func pushNonceToList(_ nonce: DEInt64BasedNonce, limit: Int) throws {
        let storedNonces = try self.cryptoNonceList()
        
        let list: [DEInt64BasedNonce]
        if var nonces = storedNonces {
            nonces.insert(nonce, at: 0)
            nonces = Array(nonces.prefix(limit))
            list = nonces
        }
        else {
            list = [nonce]
        }
        try self.setCryptoNonceList(list)
    }
    
    func migrateMessagingNonceToList() throws -> DEInt64BasedNonce? {
        
        guard let nonce = try self.cryptoMessgingNonce() else {
            return nil
        }
        
        try self.pushNonceToList(nonce)
        
        return nonce
        
    }
    
    func appendLogs(_ line: String, linesLimit: Int = 75) throws {
        let limit = max(1, linesLimit)
        
        var lines: [String] = []
        if let logs = try self.cryptoLogs() {
            lines = logs.components(separatedBy: .newlines)
        }
        lines.insert(line, at: 0)
        lines = Array(lines.prefix(limit))
        let newLogs = lines.joined(separator: "\n")
        try self.setCryptoLogs(newLogs)
    }
    
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
    
    public func setCryptoLogs(_ logs: String) throws {
        guard let data = logs.data(using: .utf8) else {
            throw DECryptoError.stringEncodingFailed
        }
        try self.addOrUpdateData(query: .writeCryptoItemQuery(service: .logs, data: data as NSData))
    }
    
    public func cryptoLogs() throws -> String? {
        let data = try self.readNullableData(query: .readCryptoItemQuery(service: .logs))
        if let data = data {
            if let string = String.init(data: data, encoding: .utf8) {
                return string
            }
        }
        return nil
    }
    
    public func removeCryptoMessagingNonce() throws {
        try self.delete(query: .deleteCryptoItemQuery(service: .messagingNonce))
    }
    
    public func cryptoMessgingNonce() throws -> DEInt64BasedNonce? {
        let storedData = try self.readNullableData(query: .readCryptoItemQuery(service: .messagingNonce))
        guard let data = storedData else {
            return nil
        }
        let nonce = DEInt64BasedNonce.init(data: data)
        return nonce
    }
    
    public func setCryptoNonceList(_ list: [DEInt64BasedNonce]) throws {
        let datas: [Data] = list.map{$0.nonce}
        let builder = NonceList.getBuilder()
        builder.nonces = datas
        let list = try builder.build()
        let listData = list.data() as NSData
        try self.addOrUpdateData(query: .writeCryptoItemQuery(service: .nonceList, data: listData))
    }
    
    public func cryptoNonceList() throws -> [DEInt64BasedNonce]? {
        guard let storedData = try self.readNullableData(query: .readCryptoItemQuery(service: .nonceList)) else {
            return nil
        }
        
        let list = try NonceList.parseFrom(data: storedData)
        let nonces: [DEInt64BasedNonce] = list.nonces.map{DEInt64BasedNonce.init(data: $0)}
        return nonces
    }
    
    public func resetCryptoStorage() throws {
        let itemsToDelete = DEKeychainQuery.Access.CryptoService.all
        
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
    internal static let cryptoMessagingNonceList = DEKeychainQuery.Service.init("im.dlg.crypto.nonce.list")
    internal static let cryptoLogs = DEKeychainQuery.Service.init("im.dlg.crypto.logs")
    
}


internal extension DEKeychainQuery.Access {
    
    internal enum CryptoService {
        
        case messagingNonce
        case sharedSecret
        case nonceList
        case logs
        
        internal static let all: [CryptoService] = [.messagingNonce, .sharedSecret, .nonceList]
        
        var service: DEKeychainQuery.Service {
            switch self {
            case .messagingNonce: return .cryptoMessagingKey
            case .sharedSecret: return .cryptoSharedSecret
            case .nonceList: return .cryptoMessagingNonceList
            case .logs: return .cryptoLogs
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
