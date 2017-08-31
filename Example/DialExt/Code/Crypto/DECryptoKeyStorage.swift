//
//  DECryptoKeyStorage.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 16/08/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import DLGSodium


public protocol DECryptoKeyStorage {
    
    func keyPair() throws -> DECryptoKeyPair?
    
    func setKeyPair(_ keyPair: DECryptoKeyPair) throws
    
    func deleteKeyPair() throws
    
}

extension DEKeychainDataProvider: DECryptoKeyStorage {

    public func deleteKeyPair() throws {
        try self.delete(query: .init(access: self.access, operation: .delete))
    }
    
    public func setKeyPair(_ keyPair: DECryptoKeyPair) throws {
        let protoPair = keyPair.keyPair
        let data = protoPair.data()
        try self.addOrUpdateData(access: self.access, data: data)
    }
    
    public func keyPair() throws -> DECryptoKeyPair? {
        let data: Data
        do {
            data = try self.readData(access: self.access)
        } catch {
            if let keychainError = error as? DEKeychainQueryError, keychainError == DEKeychainQueryError.noResults {
                return nil
            }
            throw error
        }
        let protoPair = try KeyPair.parseFrom(data: data)
        let pair = DECryptoKeyPair.init(keyPair: protoPair)
        return pair
    }
    
    public func currentKeyPair() throws -> DECryptoKeyPair? {
        do {
            let data = try self.readData(query: .init(access: self.access, operation: .read(config: nil)))
            let protoPair = try KeyPair.parseFrom(data: data)
            let pair = DECryptoKeyPair.init(keyPair: protoPair)
            return pair
        }
        catch {
            if let keychainError = error as? DEKeychainQueryError, keychainError == DEKeychainQueryError.noResults {
                return nil
            }
            throw error
        }
        
    }
    
    public func hasCurrentKeyPair() throws -> Bool {
        do {
            _ = try self.currentKeyPair()
        } catch {
            if let keychainError = error as? DEKeychainQueryError, keychainError == DEKeychainQueryError.noResults {
                return false
            }
        }
        return true
    }
    
    private func generateKeyPair() throws -> DECryptoKeyPair {
        let sodium = Sodium()!
        guard let randomData = sodium.randomBytes.buf(length: 32) else {
            throw DECryptoError.failToGenerateRandomData
        }
        guard let keyPair = sodium.keyExchange.keyPair(seed: randomData) else {
            throw DECryptoError.failToGenerateKeyPair
        }
        return DECryptoKeyPair.init(keyExchangeKeyPair: keyPair)
    }
    
    private var access: DEKeychainQuery.Access {
        return DEKeychainQuery.Access.init(DEKeychainQuery.Service.init("im.dlg.crypto.keypair"),
                                           account: "im.dlg.crypto-private")
    }
}

