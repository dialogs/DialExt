//
//  DECryptoIncomingDataDecryptor.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 21/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import DLGSodium

public protocol DECryptoIncomingDataDecrypting {
    func decrypt(incomingData data: Data, rx: Data, nonceData: Data) throws -> Data
}


public class DECryptoIncomingDataDecryptor: DECryptoIncomingDataDecrypting {
    
    private let sodium: Sodium
    
    public init(sodium: Sodium = Sodium()) {
        self.sodium = sodium
    }
    
    public func decrypt(incomingData data: Data, rx: Data, nonceData: Data) throws -> Data {
        let box = self.sodium.secretBox
        guard let decodedData = box.open(authenticatedCipherText: data.toBytes, secretKey: rx.toBytes, nonce: nonceData.toBytes) else {
            throw DECryptoError.failToDecodeMessage
        }
        return decodedData.toData
    }
    
}
