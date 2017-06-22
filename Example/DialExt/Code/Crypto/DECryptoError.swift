//
//  DECryptoError.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 20/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public enum DECryptoError: Error {
    case failToInitializeSodium
    case failToGenerateRandomData
    case failToGenerateKeyPair
    case failToGenerateSharedSecret
    case wrongNonce
    case failToDecodeMessage
}
