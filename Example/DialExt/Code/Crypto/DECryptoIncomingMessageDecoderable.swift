//
//  DECryptoIncomingMessageDecoder.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 21/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import DLGSodium

public struct DecodedMessage {
    var alertingPush: AlertingPush
}


/// Responsible for decoding incoming messages. **Not thread-safe**
public protocol DECryptoIncomingMessageDecoderable {
    func decodeIncomingMessage(_ data: Data, nonce: DEInt64BasedNonce) throws -> DecodedMessage
}

public class DECryptoIncomingMessageDecoder: DECryptoIncomingMessageDecoderable {
    
    private let storage: DECryptoStorage
    
    private let sodium: Sodium
    
    private let decrypter: DECryptoIncomingDataDecrypting
    
    public init(storage: DECryptoStorage) throws {
        guard let sodium = Sodium() else {
            throw DECryptoError.failToInitializeSodium
        }
        self.sodium = sodium
        self.storage = storage
        
        self.decrypter = DECryptoIncomingDataDecryptor.init(sodium: self.sodium)
    }
    
    public func decodeIncomingMessage(_ data: Data, nonce: DEInt64BasedNonce) throws -> DecodedMessage {
        let protoData = try self.decrypt(data, nonce: nonce)
        let push = try AlertingPush.init(serializedData: protoData)
        return DecodedMessage(alertingPush: push)
    }
    
    private func isValidNonce(_ nonce: DEInt64BasedNonce) throws -> Bool {
        var storedNonce = DEInt64BasedNonce.init(value: 0)
        do {
            storedNonce = try self.storage.cryptoSeqNOnce()
        }
        catch {
            if !self.isNoResultsKeychainError(error) {
                throw error
            }
        }
        return nonce.value > storedNonce.value
    }
    
    private func isNoResultsKeychainError(_ error: Error) -> Bool {
        if let keychainError = error as? DEKeychainQueryError, keychainError == DEKeychainQueryError.noResults {
            return true
        }
        return false
    }
    
    private func decrypt(_ data: Data, nonce: DEInt64BasedNonce, shouldStoreNewNonce: Bool = true) throws -> Data {
        let storedNonce = try self.storage.cryptoSeqNOnce()
        
        guard try self.isValidNonce(nonce) else {
            print("Ignoring invalid nonce \(nonce). Stored: \(try! self.storage.cryptoSeqNOnce())")
            throw DECryptoError.wrongNonce
        }
        
        let nonceData = Data.de_withValue(storedNonce) as SecretBox.Nonce
        let readKey = try self.storage.sharedSecretRx() as SecretBox.Key
        
        // Decrypt message data
        let decryptedData = try self.decrypter.decrypt(incomingData: data, rx: readKey, nonceData: nonceData)
        
        if shouldStoreNewNonce {
            try! self.storage.setCryptoSeqNOnce(nonce)
        }
        
        return decryptedData
    }
    
}
