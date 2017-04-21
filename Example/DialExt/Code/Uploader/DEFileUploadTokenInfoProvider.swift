//
//  DEFileUploadTokenInfoProvider.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 14/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public protocol DEFileUploadTokenInfoProvidable {
    
    var authId: DEAuthId? { get }
    
    var signedAuthId: Data? { get }
    
}

extension DEFileUploadTokenInfoProvidable {
    var authInfo: DEFileUploader.RequestBuilder.AuthInfo? {
        if let id = self.authId, let signedId = self.signedAuthId {
            return DEFileUploader.RequestBuilder.AuthInfo.init(authId: id, signedAuthId: signedId)
        }
        return nil
    }
}

/**
 * Provides auth id and signed auth id for subscriptnig upload requests.
 * Thread-safe.
 */
class DEFileUploadTokenInfoProvider: DEFileUploadTokenInfoProvidable {
    
    let keychain = DEKeychainDataProvider.init()
    
    let groupId: String
    
    public init(keychainGroupId: String) {
        self.groupId = keychainGroupId
    }
    
    
    var authId: DEAuthId? {
        return try? keychain.authId(groupId: groupId)
    }
    
    var signedAuthId: Data? {
        return try? keychain.signedAuthId(groupId: groupId)
    }
    
}
