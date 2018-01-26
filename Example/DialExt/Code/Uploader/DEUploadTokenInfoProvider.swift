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
    
    func provideAuth() throws -> DEQueryAuth {
        if let id = try? self.provideAuthId(), let signedId = try? self.provideSignedAuthId() {
            return DEUploadAuth.init(authId: id, signedAuthId: signedId)
        } else if let providenToken = try? self.provideToken(), let token = providenToken {
            return DEUploadTokenAuth.init(token: token)
        }
        
        throw DEUploadError.invalidAuthInfo
    }
}
