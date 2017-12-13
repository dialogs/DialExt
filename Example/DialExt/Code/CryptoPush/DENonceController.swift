//
//  DENonceController.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 09/12/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public class DENonceController {
    
    private let storage: DECryptoStorage
    
    public init(storage: DECryptoStorage) {
        self.storage = storage
    }
    
    public func pushNonce(_ nonce: DEInt64BasedNonce) throws {
        try self.storage.pushNonceToList(nonce)
    }
    
    private func log(list: [DEInt64BasedNonce], nonce: DEInt64BasedNonce) {
        let listDescr = list.map({$0.value.description})
        let data = Date().description
        let log = "[\(data)]: got \(nonce.value.description), checking: [\(listDescr)]"
        DEGroupLog(log)
    }
    
    public func validateNonce(_ nonce: DEInt64BasedNonce) throws {
        if let nonceList = try self.storage.cryptoNonceList() {
            self.log(list: nonceList, nonce: nonce)
            
            if nonceList.contains(nonce) {
                throw DECryptoError.nonceAlreadyUsedBefore
            }
            
            guard nonceList.count > 0 else {
                return
            }
            
            guard let minNonce = nonceList.min() else {
                throw DECryptoError.failToProcessNonceList
            }
            
            guard nonce > minNonce else {
                throw DECryptoError.wrongNonce
            }
        }
        else {
            // Old-way
            guard let storedNonce = try self.storage.migrateMessagingNonceToList() else {
                // No nonce stored.
                return
            }
            
            guard nonce > storedNonce else {
                throw DECryptoError.wrongNonce
            }
            
        }
    }
    
}

