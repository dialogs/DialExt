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
    
    internal init(_ box: Box.KeyPair) {
        self.init(publicKey: box.publicKey, secretKey: box.secretKey)
    }
    
    internal init(_ box: KeyExchange.KeyPair) {
        self.init(publicKey: box.publicKey, secretKey: box.secretKey)
    }
}
