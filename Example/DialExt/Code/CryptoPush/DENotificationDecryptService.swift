//
//  DENotificationDecryptService.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 27/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import UserNotifications


@available(iOS 10, *) public class DENotificationDecryptService {
    
    private let decoder: DECryptoIncomingMessageDecoderable
    
    private let errorStorage: DECryptoPushErrorStorage?
    
    public var shouldWriteErrors: Bool = true
    
    public convenience init(keychainGroup: String) {
        let keychain = DEKeychainDataProvider.init()
        let storage = DEGroupedKeychainDataProvider.init(groupId: keychainGroup, keychainProvider: keychain)
        
        let decoder = try! DECryptoIncomingMessageDecoder.init(storage: storage)
        let errorStorage = storage
        
        self.init(decoder: decoder, errorStorage: errorStorage)
    }
    
    public init(decoder: DECryptoIncomingMessageDecoderable, errorStorage: DECryptoPushErrorStorage? = nil) {
        self.decoder = decoder
        self.errorStorage = errorStorage
    }
    
    public func decrypt(notification: UNNotificationRequest) throws -> UNNotificationContent {
        
        guard let data = notification.content.encryptedAlertData else {
            throw failure(DEEncryptedPushNotificationError.noAlertData)
        }
        
        guard let nonce = notification.content.encryptedAlertNonce else {
            throw failure(DEEncryptedPushNotificationError.noNonce)
        }
        
        let decodedAlert = try self.decoder.decodeIncomingMessage(data, nonce: nonce)
        
        guard let content = notification.content.mutableCopy() as? UNMutableNotificationContent else {
            throw failure(DEEncryptedPushNotificationError.mutableContentUnavailable)
        }
        
        let title: String
        do {
            title = try decodedAlert.alertingPush.supposeTitle()
        }
        catch {
            failure(error)
            title = ""
        }
        
        let body: String
        do {
            body = try decodedAlert.alertingPush.supposeBody()
        }
        catch {
            failure(error)
            body = ""
        }
        
        content.body = body
        content.title = title
        
        return notification.content
    }
    
    @discardableResult private func failure(_ error: Error) -> Error {
        if let storage = self.errorStorage, self.shouldWriteErrors {
            try? storage.setCryptoPushErrorDescription(error.localizedDescription)
        }
        return error
    }
}
