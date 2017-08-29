//
//  DECryptoManagable.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 16/08/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation


public struct EnsuredKeyPair {
    public let keyPair: DECryptoKeyPair
    public let isNewGenerated: Bool
}


public struct DESharedSecret {
    
    public let rx: Data
    
    public let tx: Data
    
    public init(rx: Data, tx: Data) {
        self.rx = rx
        self.tx = tx
    }
    
    public init(protobufSharedSecret: SharedSecret) {
        self.rx = protobufSharedSecret.rx
        self.tx = protobufSharedSecret.tx
    }
    
    public var protobufSharedSecret: SharedSecret {
        let protoSecretBuilder = SharedSecret.getBuilder()
        protoSecretBuilder.rx = self.rx
        protoSecretBuilder.tx = self.tx
        let secret = try! protoSecretBuilder.build()
        return secret
    }
}


public protocol DECryptoManagable {
    
    @discardableResult func ensureKeyPair(resetCurrent: Bool) throws -> (pair: DECryptoKeyPair, isNewOne: Bool)
    
    @discardableResult func resetSharedSecret(keyPair: DECryptoKeyPair, publicKey: Data) throws -> DESharedSecret
    
    func getSharedSecret() throws -> DESharedSecret?
    
    func clearStorage() throws
    
}

public extension DECryptoManagable {
    
    func hasSharedSecret() -> Bool {
        do {
            let secret = try self.getSharedSecret()
            return secret != nil
        }
        catch {
            DESErrorLog("Fail to fetch shared secret")
            return false
        }
    }
}

public class DECryptoManager: DECryptoManagable {
    
    public func clearStorage() throws {
        try self.keyStorage.deleteKeyPair()
        try self.storage.resetCryptoStorage()
    }

    private let storage: DECryptoStorage
    private let keyStorage: DECryptoKeyStorage
    private let keyGenerator: DECryptoKeyPairGeneratable
    
    public init(storage: DECryptoStorage,
                keyStorage: DECryptoKeyStorage = DEKeychainDataProvider.init(),
                generator: DECryptoKeyPairGeneratable = DECryptoKeyPairGenerator()) {
        self.storage = storage
        self.keyStorage = keyStorage
        self.keyGenerator = generator
    }
    
    
    public func ensureKeyPair(resetCurrent: Bool) throws -> (pair: DECryptoKeyPair, isNewOne: Bool) {
        if resetCurrent {
            let keyPair = try self.setupNewKeyPair()
            return (keyPair, true)
        }
        else {
            if let keyPair = try self.keyStorage.keyPair() {
                return (keyPair, false)
            }
            else {
                let keyPair = try self.setupNewKeyPair()
                return (keyPair, true)
            }
        }
    }
    
    public func getSharedSecret() throws -> DESharedSecret? {
        return try self.storage.cryptoSharedSecret()
    }
    
    public func resetSharedSecret(keyPair: DECryptoKeyPair, publicKey: Data) throws -> DESharedSecret {
        let sharedSecret = try self.keyGenerator.generateSharedSecret(keyPair: keyPair, publicKey: publicKey)
        try self.storage.setCryptoSharedSecret(sharedSecret)
        return sharedSecret
    }
    
    private func setupNewKeyPair() throws -> DECryptoKeyPair {
        let keyPair = try self.keyGenerator.generateKeyPair()
        try self.keyStorage.setKeyPair(keyPair)
        return keyPair
    }
    
    private func shouldResetCurrentKeyPair() -> Bool {
        let currentKeyPair = try? self.keyStorage.keyPair()
        return currentKeyPair != nil
    }
    
}

