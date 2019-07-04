//
//  DECryptoKeyPairGenerator.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 16/08/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import DLGSodium

public protocol DECryptoKeyPairGeneratable {
    
    func generateKeyPair() throws -> DECryptoKeyPair
    
    func generateSharedSecret(keyPair: DECryptoKeyPair, publicKey: Data) throws -> DESharedSecret
}

public class DECryptoKeyPairGenerator: DECryptoKeyPairGeneratable {
    
    public func generateKeyPair() throws -> DECryptoKeyPair {
        let sodium = Sodium.init()
        guard let randomData = sodium.randomBytes.buf(length: 32) else {
            throw DECryptoError.failToGenerateRandomData
        }
        guard let keyPair = sodium.keyExchange.keyPair(seed: randomData) else {
            throw DECryptoError.failToGenerateKeyPair
        }
        return DECryptoKeyPair.init(keyExchangeKeyPair: keyPair)
    }
    
    public func generateSharedSecret(keyPair: DECryptoKeyPair, publicKey: Data) throws -> DESharedSecret {
        let sodium = Sodium.init()
        guard let sharedSecret = sodium.keyExchange.sessionKeyPair(publicKey: keyPair.publicKey.toBytes,
                                                             secretKey: keyPair.secretKey.toBytes,
                                                             otherPublicKey: publicKey,
                                                             side: .CLIENT) else {
                                                                throw DECryptoError.failToGenerateSharedSecret
        }
        return DESharedSecret.init(rx: sharedSecret.rx, tx: sharedSecret.tx)
    }
    
    public init() {
        
    }
}
