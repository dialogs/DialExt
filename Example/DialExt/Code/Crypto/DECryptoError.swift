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

public enum DEEncryptedPushNotificationError: Error {
    case noAlertData
    case noNonce
    case noAlertDataTitle
    case noAlertDataBody
    case noAlertBadge
    case noAlertSound
    case invalidLocalizationKey
    case mutableContentUnavailable
}


public struct DEDetailedError: Error {
    
    public let baseError: Error
    
    public let userInfo: UserInfo
    
    public var basicError: BasicError? {
        return baseError as? BasicError
    }
    
    public init(baseError: Error, info: UserInfo = [:]) {
        self.baseError = baseError
        self.userInfo = info
    }
    
    public init(_ basicError: BasicError, info: UserInfo = [:]) {
        self.init(baseError: basicError, info: info)
    }
    
    public enum BasicError: Error {
        case invalidLocalizationKey
        case notificationAlertTitleLocalizationKey
        case notificationAlertBodyLocalizationKey
    }
    
    public var localizedDescription: String {
        return self.baseError.localizedDescription
    }
    
    public static func invalidLocalizationKey(_ key: String?) -> DEDetailedError {
        var info: UserInfo = [:]
        if let key = key {
            info[UserInfoKey.key] = key
        }
        return self.init(.invalidLocalizationKey, info: info)
    }
    
    public static func notificationAlertTitleLocalizationKey(_ key: String?) -> DEDetailedError {
        var info: UserInfo = [:]
        if let key = key {
            info[UserInfoKey.key] = key
        }
        return self.init(.notificationAlertTitleLocalizationKey, info: info)
    }
    
    public static func notificationAlertBodyLocalizationKey(_ key: String?) -> DEDetailedError {
        var info: UserInfo = [:]
        if let key = key {
            info[UserInfoKey.key] = key
        }
        return self.init(.notificationAlertBodyLocalizationKey, info: info)
    }
    
    public typealias UserInfo = [AnyHashable : Any]
    
    public struct UserInfoKey {
        public static let key = "im.dialext.de_error.key"
    }
}
