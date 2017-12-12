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
    
    private let nonceController: DENonceController
    
    public init(storage: DECryptoStorage,
                decryptor: DECryptoIncomingDataDecrypting = DECryptoIncomingDataDecryptor.init()) throws {
        self.storage = storage
        self.decryptor = decryptor
        self.nonceController = DENonceController.init(storage: storage)
    }
    
    public func decodeIncomingMessage(_ data: Data, nonce: DEInt64BasedNonce) throws -> DecodedMessage {
        let protoData = try self.decrypt(data, nonce: nonce)
        let push = try AlertingPush.parseFrom(data: protoData)
        return DecodedMessage(alertingPush: push)
    }
    
    private func isNoResultsKeychainError(_ error: Error) -> Bool {
        if let keychainError = error as? DEKeychainQueryError, keychainError == DEKeychainQueryError.noResults {
            return true
        }
        return false
    }
    
    private func decrypt(_ data: Data, nonce: DEInt64BasedNonce, shouldStoreNewNonce: Bool = true) throws -> Data {
        
        try self.nonceController.validateNonce(nonce)
        
        guard let secret = try self.storage.cryptoSharedSecret() else {
            throw DECryptoError.noSharedSecretStored
        }
        let decodedMessage = try self.decryptor.decrypt(incomingData: data,
                                                              rx: secret.rx,
                                                              nonceData: nonce.bigEndianData)
        
        if shouldStoreNewNonce {
            do {
                try self.nonceController.pushNonce(nonce)
            }
            catch {
                throw DECryptoError.failToStoreNewNonce
            }
        }
        
        return decodedMessage
    }
}
