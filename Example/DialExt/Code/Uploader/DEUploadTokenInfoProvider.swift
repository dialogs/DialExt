//
//  DEUploadAuthProvider.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 14/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public protocol DEUploadAuthProviding {
    
    func provideAuthId() throws -> DEAuthId
    
    func provideSignedAuthId() throws -> Data
    
}

extension DEUploadAuthProviding {
    
    func checkIfAuthProviden() -> Bool {
        return (try? self.provideSignedAuthId()) != nil
    }
    
    func provideAuth() throws -> DEUploadAuth {
        guard let id =  try? self.provideAuthId(), let signedId = try? self.provideSignedAuthId() else {
            throw DEUploadError.invalidAuthInfo
        }
        return DEUploadAuth.init(authId: id, signedAuthId: signedId)
    }
}

/**
 * Provides auth id and signed auth id for subscriptnig upload requests.
 * Thread-safe.
 */
class DEUploadAuthProvider: DEUploadAuthProviding {
    
    let keychain = DEKeychainDataProvider.init()
    
    let groupId: String
    
    public init(keychainGroupId: String) {
        self.groupId = keychainGroupId
    }
    
    func provideAuthId() throws -> DEAuthId {
        return try keychain.authId(groupId: self.groupId)
    }
    
    func provideSignedAuthId() throws -> Data {
        return try keychain.signedAuthId(groupId: self.groupId)
    }
    
}
