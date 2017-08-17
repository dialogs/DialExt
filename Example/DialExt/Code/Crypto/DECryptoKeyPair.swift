//
//  DECryptoKeyPair.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 20/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import DLGSodium


public struct DECryptoKeyPair {
    
    public let publicKey: Data
    
    internal let secretKey: Data
    
    public init(publicKey: Data, secretKey: Data) {
        self.publicKey = publicKey
        self.secretKey = secretKey
    }
    
    // Sodium KeyExhange compatibility
    
    internal init(keyExchangeKeyPair: KeyExchange.KeyPair) {
        self.publicKey = keyExchangeKeyPair.publicKey
        self.secretKey = keyExchangeKeyPair.secretKey
    }
    
    // KeyPair compatibility
    
    internal var keyPair: KeyPair {
        let builder = KeyPair.getBuilder()
        builder.publicKey = self.publicKey
        builder.secretKey = self.secretKey
        return try! builder.build()
    }
    
    internal init (keyPair: KeyPair) {
        self.publicKey = keyPair.publicKey
        self.secretKey = keyPair.secretKey
    }
    
}
