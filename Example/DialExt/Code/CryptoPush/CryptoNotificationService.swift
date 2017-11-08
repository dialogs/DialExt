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
    
    open var debugModeTextReplacementEnabled: Bool = false
    
    open var insertSecureSymbolIntoTitle: Bool = true
    
    open var contentHandler: ((UNNotificationContent) -> Void)!
    
    open var bestAttemptContent: UNMutableNotificationContent!
    
    private func createDecoder() throws -> DECryptoIncomingMessageDecoderable {
        
        guard let keychainGroup = self.keychainGroup else {
            throw DECryptoError.noKeychainGroupProvided
        }
        
        let keychain = DEKeychainDataProvider.init()
        let storage = keychain.cryptoStorage(groupId: keychainGroup)
        let decoder = try DECryptoIncomingMessageDecoder.init(storage: storage)
        return decoder
    }
    
    /**
     Decrypts notification and put it to 'bestAttemptContent' var.
     If 'debugModeTextReplacementEnabled' is on – put explanation text into 'bestAttemptContent' if an error occured.
     */
    open func decryptNotification(request: UNNotificationRequest) throws {
        let setBodyIfInDebugMode: (String) -> () = { body in
            if self.debugModeTextReplacementEnabled {
                self.bestAttemptContent.body = body
            }
        }
        
        let decoder: DECryptoIncomingMessageDecoderable
        do {
            decoder = try self.createDecoder()
        }
        catch {
            DESErrorLog("Fail to init decoder")
            DEErrorLog("Fail to init decoder: \(error.localizedDescription)")
            
            setBodyIfInDebugMode("Fail to init decoder: \(error.localizedDescription)")
            
            throw error
            
            return
        }
        
        let remoteNonce: Int64
        let data: Data
        do {
            remoteNonce = try request.content.nonce()
            data = try request.content.encodedData()
        }
        catch {
            DESErrorLog("No [needed data] or encrypted data in notification")
            DEErrorLog("\(error), \(error.localizedDescription)")
            setBodyIfInDebugMode(error.localizedDescription)
            throw error
            return
        }
        
        let remoteNonceObject = DEInt64BasedNonce.init(remoteNonce)
        
        var message: DecodedMessage
        do {
            message = try decoder.decodeIncomingMessage(data, nonce: remoteNonceObject)
        }
        catch {
            DESErrorLog("Fail to decode message")
            DEErrorLog("Fail to decode message: \(error.localizedDescription)")
            setBodyIfInDebugMode(String(describing: error))
            throw error
            return
        }
        
        let push = message.alertingPush
        
     let secureSymbol = "🔏 "
        
        do {
            var title = try push.supposeTitle()
            if self.insertSecureSymbolIntoTitle {
                title = secureSymbol.appending(title)
            }
            self.bestAttemptContent.title = title
        }
        catch {
            DESErrorLog("No title in push")
            self.bestAttemptContent.title = secureSymbol
        }
        
        do {
            let body = try push.supposeBody()
            self.bestAttemptContent.body = body
        }
        catch {
            DESErrorLog("No body in push")
            setBodyIfInDebugMode("Fail to execute body from \(push.description)")
        }
        
        DESLog("Notification Service succesfully modified the message")
    }
    
    override open func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        try? self.decryptNotification(request: request)
        
        contentHandler(self.bestAttemptContent)
    }
    
    override open func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
}

public enum DENotificationCryptoContentError: LocalizedError {
    
    case noUserInfo
    
    case noEncryptedData
    case dataInvalidFormat
    case dataInvalidFormatEncoding
    
    case noNonce
    case nonceInvalidFormat
    case nonceInvalidFormatEncoding
    
    public var errorDescription: String? {
        return self.localizedDescription
    }
    
    public var localizedDescription: String {
        
        switch self {
        case .noUserInfo: return"User info does not contain expected content"
            
        case .noEncryptedData: return "User info's content does not have encypted data"
        case .dataInvalidFormat: return "Encoded data has unexpected format"
        case .dataInvalidFormatEncoding: return "Encoded data has unexpected format encoding"
        
        case .noNonce: return "User info's content does not have needed data"
        case .nonceInvalidFormat: return "Needed data has unexpected format"
        case .nonceInvalidFormatEncoding: return "Needed data has unexpected format encoding"
            
        }
    }
}

@available(iOSApplicationExtension 10.0, *)
public extension UNNotificationContent {
    
    public var encodingInfo: [String : AnyObject]? {
        guard let info = self.userInfo["user_info"] as? [String : AnyObject] else {
            DESErrorLog("No user info in notification")
            return nil
        }
        return info
    }
    
    public func encodedData() throws -> Data {
        guard let userInfo = self.encodingInfo else {
            throw DENotificationCryptoContentError.noUserInfo
        }
        guard let dataValue = userInfo["encrypted_data"] else {
            throw DENotificationCryptoContentError.noEncryptedData
        }
        guard let base64String = dataValue as? String else {
            throw DENotificationCryptoContentError.dataInvalidFormat
        }
        
        guard let data = Data.init(base64Encoded: base64String) else {
            throw DENotificationCryptoContentError.dataInvalidFormatEncoding
        }
        
        return data
    }
    
    public func nonceString() throws -> String {
        guard let userInfo = self.encodingInfo else {
            throw DENotificationCryptoContentError.noUserInfo
        }
        guard let nonceAnyValue = userInfo["nonce"] else {
            throw DENotificationCryptoContentError.noNonce
        }
        guard let nonceString = nonceAnyValue as? String else {
            throw DENotificationCryptoContentError.nonceInvalidFormat
        }
        return nonceString
    }
    
    public func nonce() throws -> Int64 {
        let nonceString = try self.nonceString()
        guard let nonceLong = Int64.init(nonceString) else {
            throw DENotificationCryptoContentError.nonceInvalidFormatEncoding
        }
        return nonceLong
    }
    
}
