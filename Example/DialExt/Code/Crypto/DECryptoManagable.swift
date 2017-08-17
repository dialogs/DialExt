//
//  DECryptoManagable.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 16/08/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation


protocol DECryptoManagable {
    
    func ensureKeyPair(resetCurrent: Bool) -> DECryptoKeyPair
    
    func storeSharedSecret(_ secret: DECryptoKeyPair) throws
    
    func clearStorage() throws
    
}

public class DECryptoManager: DECryptoManagable {
    
    func clearStorage() throws {
        
    }


    private let torage: DECryptoStorage
    
    public init(storage: DECryptoStorage,
                keyStorage: DECryptoKeyStorage,
                generator: DECryptoKeyPairGeneratable) {
        
    }
    
    func ensureKeyPair(resetCurrent: Bool) -> DECryptoKeyPair {
        
    }
    
    func storeSharedSecret(_ secret: DECryptoKeyPair) throws {
        
    }
    
}

