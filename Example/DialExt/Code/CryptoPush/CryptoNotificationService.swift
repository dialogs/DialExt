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
    
    open var debugLogsAllowed: Bool = false
    
    open var extractRequiredUpdateInfo: Bool = true
    
    open var insertSecureSymbolIntoTitle: Bool = true
    
    open var insertSpecialSecureSymbolToDecryptFailedTitle: Bool = true
    
    open var insertFailReportToRequestUserInfo: Bool = true
    
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
        do {
            try defaultWayDecrypt(request: request)
        }
        catch {
            if self.insertSpecialSecureSymbolToDecryptFailedTitle {
                var title = self.bestAttemptContent.title
                title.wrap(byPrefix: "🔒 ", suffix: "")
            }
            
            let nonce = try? request.content.nonceString()
            let report = CryptoFailReport.init(error: error, nonce: nonce)
            if self.insertFailReportToRequestUserInfo {
                self.bestAttemptContent.setCryptoFailReport(report)
            }
            
            self.onDidFail(report: report)
            throw error
        }
    }
    
    /**
     Override this function if you want to keep original decription, but to send/keep information about fail.
     */
    open func onDidFail(report: CryptoFailReport) {
        
    }
    
    override open func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        
        if self.debugLogsAllowed {
            DEGroupLogger.setupSharedLogger(keychainGroup: self.keychainGroup)
        }
        
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        try? self.decryptNotification(request: request)
        
        contentHandler(self.bestAttemptContent)
    }
    
    private func defaultWayDecrypt(request: UNNotificationRequest) throws {
        
        if self.extractRequiredUpdateInfo,
            let info = NotificationContentRequiredUpdateExtractor().execute(content: request.content) {
            
            let group = DEKeychainDataProvider().shared(groupName: self.keychainGroup)
            let storage = RequiredUpdateKeychainStorage.init(keychain: group)
            
            do {
                try storage.writeReqUpdateInfo(info)
            }
            catch {
                DEErrorLog("Fail to write required update info. \(error)")
                DESErrorLog("Fail to write required update info")
            }
            
            // Required update can't have any encrypted info.
            
            return
        }
        
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
        }
        
        let push = message.alertingPush
        
        if let peer = push.peer {
            self.bestAttemptContent.setPeer(peer)
        }
        else {
            DESLog("Notification does not contain peer")
        }
        
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

@available(iOS 10.0, *)
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
    
    public var failReportDescription: String? {
        return UNNotificationContent.failReportDescription(fromUserInfo: self.userInfo)
    }
    
    public static func failReportDescription(fromUserInfo: [AnyHashable : Any]?) -> String? {
        guard let info = fromUserInfo else {
            return nil
        }
        return info[CryptoFailReport.userInfoKey] as? String
    }
    
}

@available(iOS 10.0, *)
public extension UNNotificationContent {
    public static let peerUserInfoKey = "im.dlg.peer"

}

@available(iOS 10.0, *)
public extension UNMutableNotificationContent {
    
    func setCryptoFailReport(_ report: CryptoFailReport) {
        self.userInfo[CryptoFailReport.userInfoKey] = report.description
    }
    
    func setPeer(_ peer: Peer) {
        self.userInfo[UNNotificationContent.peerUserInfoKey] = peer.data()
    }
    
}

public extension Peer {
    public static func createWithUserInfo(_ userInfo: [AnyHashable : Any]?) -> Peer? {
        guard let info = userInfo else {
            return nil
        }
        guard let peerData = info[UNNotificationContent.peerUserInfoKey] as? Data else {
            return nil
        }
        
        return try? Peer.parseFrom(data: peerData)
    }
}
