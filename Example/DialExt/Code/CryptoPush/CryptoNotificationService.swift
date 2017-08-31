//
//  CryptoNotificationService.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 31/08/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import UserNotifications

/**
 Basic class for subclassing in clients.
 To make it work – override keychain group. Nothing else needed.
 */
@available(iOSApplicationExtension 10.0, *)
open class CryptoNotificationService: UNNotificationServiceExtension {
    
    /// Override keychain group to make crypto notifications work.
    open private(set) var keychainGroup: String! = nil
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    private func createDecoder() throws -> DECryptoIncomingMessageDecoderable {
        
        guard let keychainGroup = self.keychainGroup else {
            throw DECryptoError.noKeychainGroupProvided
        }
        
        let keychain = DEKeychainDataProvider.init()
        let storage = keychain.cryptoStorage(groupId: keychainGroup)
        let decoder = try DECryptoIncomingMessageDecoder.init(storage: storage)
        return decoder
    }
    
    override open func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        
        DESLog("Notification service received a message")
        
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        let finishAsIs = {
            contentHandler(self.bestAttemptContent!)
        }
        
        let decoder: DECryptoIncomingMessageDecoderable
        do {
            decoder = try self.createDecoder()
        }
        catch {
            DESErrorLog("Fail to init decoder")
            DEErrorLog("Fail to init decoder: \(error.localizedDescription)")
            finishAsIs()
            return
        }
        
        guard let remoteNonce = request.content.nonce,
            let data = request.content.encodedData else {
                finishAsIs()
                return
        }
        
        let remoteNonceObject = DEInt64BasedNonce.init(remoteNonce)
        
        var failableMessage: DecodedMessage? = nil
        do {
            failableMessage = try decoder.decodeIncomingMessage(data, nonce: remoteNonceObject)
        }
        catch {
            DESErrorLog("Fail to decode message")
            DEErrorLog("Fail to decode message: \(error.localizedDescription)")
        }
        
        guard let message = failableMessage else {
            finishAsIs()
            return
        }
        
        let push = message.alertingPush
        guard let title = try? push.supposeTitle() else {
            DESErrorLog("Notification: no title")
            finishAsIs()
            return
        }
        guard let body = try? push.supposeBody() else {
            DESErrorLog("Notification: no body")
            finishAsIs()
            return
        }
        
        self.bestAttemptContent!.title = title
        self.bestAttemptContent!.body = body
        
        DESLog("Notification Service succesfully modified the message")
        
        contentHandler(self.bestAttemptContent!)
    }
    
    override open func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
}


@available(iOSApplicationExtension 10.0, *)
extension UNNotificationContent {
    
    var encodingInfo: [String : AnyObject]? {
        guard let info = self.userInfo["user_info"] as? [String : AnyObject] else {
            DESErrorLog("No user info in notification")
            return nil
        }
        return info
    }
    
    var encodedData: Data? {
        guard let userInfo = self.encodingInfo else {
            return nil
        }
        guard let dataValue = userInfo["encrypted_data"] else {
            DESErrorLog("Notification does not contain encrypted data")
            return nil
        }
        guard let base64String = dataValue as? String else {
            DESErrorLog("Notification encrypted data is not a string")
            return nil
        }
        
        guard let data = Data.init(base64Encoded: base64String) else {
            DESErrorLog("Notification ecnrypted data is not a base64 encoded string")
            return nil
        }
        
        return data
    }
    
    var nonce: Int64? {
        guard let userInfo = self.encodingInfo else {
            return nil
        }
        guard let nonceAnyValue = userInfo["nonce"] else {
            DESErrorLog("Notification does not contain nonce")
            return nil
        }
        guard let nonceString = nonceAnyValue as? String else {
            DEErrorLog("Notification nonce is not a string")
            return nil
        }
        guard let nonceLong = Int64.init(nonceString) else {
            DEErrorLog("Notification nonce string isn't long convertible")
            return nil
        }
        return nonceLong
    }
    
}
