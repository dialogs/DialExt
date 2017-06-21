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
    func decodeIncomingMessage(_ data: Data, nonce: DECryptoNonce) throws -> DecodedMessage
}

public class DECryptoIncomingMessageDecoder: DECryptoIncomingMessageDecoderable {
    
    private let storage: DECryptoStorage
    
    private let sodium: Sodium
    
    public init(storage: DECryptoStorage) throws {
        guard let sodium = Sodium() else {
            throw DECRyptoError.failToInitializeSodium
        }
        self.sodium = sodium
        self.storage = storage
    }
    
    public func decodeIncomingMessage(_ data: Data, nonce: DECryptoNonce) throws -> DecodedMessage {
        let protoData = try self.decode(data, nonce: nonce)
        let push = try AlertingPush.parseFrom(data: protoData)
        return DecodedMessage(alertingPush: push)
    }
    
    private func isValidNonce(_ nonce: DECryptoNonce) throws -> Bool {
        var storedNonce = Int64.min
        do {
            storedNonce = try self.storage.cryptoSeqNOnce()
        }
        catch {
            if !self.isNoResultsKeychainError(error) {
                throw error
            }
        }
        return nonce > storedNonce
    }
    
    private func isNoResultsKeychainError(_ error: Error) -> Bool {
        if let keychainError = error as? DEKeychainQueryError, keychainError == DEKeychainQueryError.noResults {
            return true
        }
        return false
    }
    
    private func decode(_ data: Data, nonce: DECryptoNonce, shouldStoreNewNonce: Bool = true) throws -> Data {
        let storedNonce = try self.storage.cryptoSeqNOnce()
        
        guard nonce > storedNonce else {
            print("Declared nonce \(nonce) is smaller or equal stored nonce \(storedNonce)")
            throw DECRyptoError.wrongNonce
        }
        
        let nonceData = Data.de_withValue(storedNonce) as SecretBox.Nonce
        
        let readKey = try self.storage.sharedSecretRx() as SecretBox.Key
        
        // Decode message data
        guard let decodedData = self.sodium.secretBox.open(authenticatedCipherText: data,
                                                           secretKey: readKey,
                                                           nonce: nonceData) else {
                                                            print("Fail to decode message (nonce is valid: \(nonce), stored: \(storedNonce))")
                                                            throw DECRyptoError.failToDecodeMessage
        }
        
        if shouldStoreNewNonce {
            try! self.storage.setCryptoSeqNOnce(nonce)
        }
        
        return decodedData
    }
    
}
