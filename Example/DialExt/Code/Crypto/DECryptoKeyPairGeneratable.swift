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
}

public class DECryptoKeyPairGenerator: DECryptoKeyPairGeneratable {
    
    public func generateKeyPair() throws -> DECryptoKeyPair {
        let sodium = Sodium.init()!
        guard let randomData = sodium.randomBytes.buf(length: 32) else {
            throw DECryptoError.failToGenerateRandomData
        }
        guard let keyPair = sodium.keyExchange.keyPair(seed: randomData) else {
            throw DECryptoError.failToGenerateKeyPair
        }
        return DECryptoKeyPair.init(keyExchangeKeyPair: keyPair)
    }
}
