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
public protocol DECryptoStorage {
    
    /// Set keys pair
    func setCryptoKeyPair(_ keyPair: Box.KeyPair) throws
    
    /// Returns last set keys pair
    func cryptoKeyPair() throws -> Box.KeyPair
    
    /// Sets nonce
    func setCryptoSeqNOnce(_ nonce: DEInt64BasedNonce) throws
    
    /// Returns last set nonce
    func cryptoSeqNOnce() throws -> DEInt64BasedNonce
    
    /// Sets shared secret rx part used for reading messages from server side
    func setSharedSecretRx(_ rx: Data) throws
    
    /// Returns shared secret rx part used for reading messages from server side
    func sharedSecretRx() throws -> Data
    
    /// Sets shared secret tx part used for encrypting outgoing messages
    func setSharedSecretTx(_ tx: Data) throws
    
    /// Returns shared secret tx part used for encrypting outgoing messages
    func sharedSecretTx() throws -> Data
    
    /// Clears all data
    func resetCryptoStorage() throws
}


extension DEGroupedKeychainDataProvider: DECryptoStorage {
    
    public func sharedSecretTx() throws -> Data {
        return try self.readData(query: .readCryptoItemQuery(service: .sharedSecretTx))
    }
    
    public func setSharedSecretTx(_ tx: Data) throws {
        let data = tx as NSData
        try self.addOrUpdateData(query: .writeCryptoItemQuery(service: .sharedSecretTx, data: data))
    }
    
    
    public func sharedSecretRx() throws -> Data {
        return try self.readData(query: .readCryptoItemQuery(service: .sharedSecretRx))
    }
    
    public func setSharedSecretRx(_ rx: Data) throws {
        let data = rx as NSData
        try self.addOrUpdateData(query: .writeCryptoItemQuery(service: .sharedSecretRx, data: data))
    }
    
    
    public func cryptoKeyPair() throws -> Box.KeyPair {
        let publicKey = try self.readData(query: .readCryptoItemQuery(service: .publicKey))
        let secretKey = try self.readData(query: .readCryptoItemQuery(service: .secretKey))
        return Box.KeyPair.init(publicKey: publicKey, secretKey: secretKey)
    }
    
    
    public func setCryptoKeyPair(_ keyPair: Box.KeyPair) throws {
        try self.addOrUpdateData(query: .writeCryptoItemQuery(service: .publicKey,
                                                              data: keyPair.publicKey as NSData))
        try self.addOrUpdateData(query: .writeCryptoItemQuery(service: .secretKey,
                                                              data: keyPair.secretKey as NSData))
    }
    
    public func cryptoSeqNOnce() throws -> DEInt64BasedNonce {
        let data = try self.readData(query: .readCryptoItemQuery(service: .nonce))
        let nonce = DEInt64BasedNonce.init(data: data)
        return nonce
    }
    
    public func setCryptoSeqNOnce(_ nonce: DEInt64BasedNonce) throws {
        let data = nonce.nonce
        try self.addOrUpdateData(query: .writeCryptoItemQuery(service: .nonce, data: data as NSData))
    }
    
    public func resetCryptoStorage() throws {
        let itemsToDelete: [DEKeychainQuery.Access.CryptoService] = [
            .nonce,.publicKey, .secretKey, .sharedSecretRx, .sharedSecretTx
        ]
        itemsToDelete.forEach { (service) in
            self.performSafeDeletion(query: .deleteCryptoItemQuery(service: .nonce))
        }
    }
    
}

public extension DEKeychainDataProvider {
    
    public func cryptoStorage(groupId: String) -> DECryptoStorage {
        return DEGroupedKeychainDataProvider.init(groupId: groupId, keychainProvider: self)
    }
    
}


internal extension DEKeychainQuery.Service {
    
    internal static let cryptoPublicKey = DEKeychainQuery.Service.init("im.dlg.crypto.keypair.public")
    internal static let cryptoSecretKey = DEKeychainQuery.Service.init("im.dlg.crypto.keypair.private")
    internal static let cryptoSharedSecretTx = DEKeychainQuery.Service.init("im.dlg.crypto.shared.tx")
    internal static let cryptoSharedSecretRx = DEKeychainQuery.Service.init("im.dlg.crypto.shared.rx")
    internal static let cryptoNonce = DEKeychainQuery.Service.init("im.dlg.crypto.nonce")
    
    
}


internal extension DEKeychainQuery.Access {
    
    internal enum CryptoService {
        case publicKey
        case secretKey
        case sharedSecretTx
        case sharedSecretRx
        case nonce
        
        var service: DEKeychainQuery.Service {
            switch self {
            case .publicKey: return .cryptoPublicKey
            case .secretKey: return .cryptoSecretKey
            case .sharedSecretTx: return .cryptoSharedSecretTx
            case .sharedSecretRx: return .cryptoSharedSecretRx
            case .nonce: return .cryptoNonce
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
        return self.init(access: .cryptoItem(service: service), operation: .add(value: data))
    }
    
    internal static func deleteCryptoItemQuery(service: DEKeychainQuery.Access.CryptoService) -> DEKeychainQuery {
        return self.init(access: .cryptoItem(service: service), operation: .delete)
    }
}
