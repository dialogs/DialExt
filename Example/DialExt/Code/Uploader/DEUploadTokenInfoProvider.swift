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

public protocol DEWriteableUploadAuthProviding: DEUploadAuthProviding {
    
    func writeAuth(_ auth: DEUploadAuth) throws
    
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
