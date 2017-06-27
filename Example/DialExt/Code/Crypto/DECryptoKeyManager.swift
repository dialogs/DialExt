//
//  DECryptoKeyManager.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 20/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import DLGSodium

/**
 Manager is responsible for all push encryption work
 # Flows
 ## Flow 1 (App):
 *User* logged in (or app updated and there is no keypair in storage yet) →
 **Manager** generates keys →
 [Keys exchanged RPC request responded] →
 **Manager** stores generated keys and shared secret from server-side response.
 
 From now all needed information for push notification decrypting stores shared keychain.
 
 
 ## Flow 2 (Extension):
 *Device* recieves notification, redirect it to extension. →
 **Manager** goes to shared keychain and collects needed data. →
 **Manager** decrypts notification (may fail due bad nonce or some other reason) →
 *Extension* replaces original notification data by decrypted message (optionally, load avatars and other stuff).
 */
class DECryptoKeyManager {
    
    public init(storage: DECryptoStorage, groupId: String) throws {
        self.storage = storage
        self.groupId = groupId
        guard let sodium = Sodium() else {
            throw DECryptoError.failToInitializeSodium
        }
        self.sodium = sodium
    }
    
    public func generateKeyPair() throws -> DECryptoKeyPair {
        
        guard let randomData = sodium.randomBytes.buf(length: 32) else {
            throw DECryptoError.failToGenerateRandomData
        }
        guard let keyPair = sodium.keyExchange.keyPair(seed: randomData) else {
            throw DECryptoError.failToGenerateKeyPair
        }
        return DECryptoKeyPair.init(keyPair)
    }
    
    public func setupSharedSecret(serverPublicKey: Data, clientKeyPair: DECryptoKeyPair) throws {
        
        guard let sessionKeyPair = sodium.keyExchange.sessionKeyPair(publicKey: clientKeyPair.publicKey,
                                                                     secretKey: clientKeyPair.secretKey,
                                                                     otherPublicKey: serverPublicKey,
                                                                     side: .client) else {
                                                                        throw DECryptoError.failToGenerateSharedSecret
        }
        try self.storage.setSharedSecretRx(sessionKeyPair.rx)
        try self.storage.setSharedSecretTx(sessionKeyPair.tx)
    }
    
    // MARK: - Private
    
    private let storage: DECryptoStorage
    
    private let sodium: Sodium
    
    private let groupId: String
}


