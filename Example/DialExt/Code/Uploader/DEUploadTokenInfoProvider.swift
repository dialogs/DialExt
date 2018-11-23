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
    
    func provideToken() throws -> String?
    
}

public protocol DEWriteableUploadAuthProviding: DEUploadAuthProviding {
    
    func writeAuth(_ auth: DEQueryAuth) throws
    
}

extension DEUploadAuthProviding {
    
    func checkIfAuthProviden() -> Bool {
        return (try? self.provideSignedAuthId()) != nil || (try? self.provideToken()) != nil
    }
    
    func provideAuth(policy: DEUploadAuthPolicy) throws -> DEQueryAuth {
        switch policy {
        case .default:
            do {
                let id = try self.provideAuthId()
                let signedId = try self.provideSignedAuthId()
                return DEUploadAuth.init(authId: id, signedAuthId: signedId)
            }
        case .token:
            do {
                if let token = try self.provideToken() {
                    return DEUploadTokenAuth.init(token: token)
                }
                throw DEUploadError.invalidAuthInfo
            }
        }
    }
    
    /// Tries fetch auth using policies one by one: default, token.
    func provideAuth() throws -> DEQueryAuth {
        
        if let auth = try? self.provideAuth(policy: .default) {
            return auth
        }
        else if let auth = try? self.provideAuth(policy: .token) {
            return auth
        }
        throw DEUploadError.invalidAuthInfo
    }
}
