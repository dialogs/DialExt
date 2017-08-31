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
    public var alertingPush: AlertingPush
}

/// Responsible for decoding incoming messages. **Not thread-safe**
public protocol DECryptoIncomingMessageDecoderable {
    func decodeIncomingMessage(_ data: Data, nonce: DEInt64BasedNonce) throws -> DecodedMessage
}

public class DECryptoIncomingMessageDecoder: DECryptoIncomingMessageDecoderable {

    private let storage: DECryptoStorage
    
    private let decryptor: DECryptoIncomingDataDecrypting
    
    public init(storage: DECryptoStorage,
                decryptor: DECryptoIncomingDataDecrypting = DECryptoIncomingDataDecryptor.init()) throws {
        self.storage = storage
        self.decryptor = decryptor
    }
    
    public func decodeIncomingMessage(_ data: Data, nonce: DEInt64BasedNonce) throws -> DecodedMessage {
        let protoData = try self.decrypt(data, nonce: nonce)
        let push = try AlertingPush.parseFrom(data: protoData)
        return DecodedMessage(alertingPush: push)
    }
    
    private func isValidNonce(_ nonce: DEInt64BasedNonce) throws -> Bool {
        var lastNonce = DEInt64BasedNonce.init(Int64.min)
        if let storedNonce = try self.storage.cryptoMessgingNonce() {
            lastNonce = storedNonce
        }
        return nonce.value > lastNonce.value
    }
    
    private func isNoResultsKeychainError(_ error: Error) -> Bool {
        if let keychainError = error as? DEKeychainQueryError, keychainError == DEKeychainQueryError.noResults {
            return true
        }
        return false
    }
    
    private func decrypt(_ data: Data, nonce: DEInt64BasedNonce, shouldStoreNewNonce: Bool = true) throws -> Data {
        guard try self.isValidNonce(nonce) else {
            throw DECryptoError.wrongNonce
        }
        
        guard let secret = try self.storage.cryptoSharedSecret() else {
            throw DECryptoError.noSharedSecretStored
        }
        let decodedMessage = try self.decryptor.decrypt(incomingData: data,
                                                              rx: secret.rx,
                                                              nonceData: nonce.bigEndianData)
        
        if shouldStoreNewNonce {
            do {
                try self.storage.setCryptoMessagingNonce(nonce)
            }
            catch {
                throw DECryptoError.failToStoreNewNonce
            }
        }
        
        return decodedMessage
    }
}
