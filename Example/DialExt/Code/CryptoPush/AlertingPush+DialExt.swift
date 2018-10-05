//
//  AlertingPush+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 27/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import UserNotifications

public extension AlertingPush {
    
    public func supposeTitle() throws -> String {
        switch self.getOneOfAlertTitle() {
        case let .locAlertTitle(localizable):
            return try localizable.buildLocalizedString()
            
        case let .simpleAlertTitle(text):
            return text
            
        case .oneOfAlertTitleNotSet:
            throw DEEncryptedPushNotificationError.noAlertDataTitle
        }
    }
    
    
    public func supposeBody() throws -> String {
        switch self.getOneOfAlertBody() {
        case let .locAlertBody(localizable): return try localizable.buildLocalizedString()
            
        case let .simpleAlertBody(text): return text
            
        case .oneOfAlertBodyNotSet:
            throw DEEncryptedPushNotificationError.noAlertDataBody
        }
    }
    
    @available(iOSApplicationExtension 10.0, *) public func supposeSound() -> UNNotificationSound {
        if let soundName = self.sound {
        return soundName.isEmpty ? UNNotificationSound.default() : UNNotificationSound.init(named: soundName)
        } else {
            return UNNotificationSound.default() 
        }
    }
    
}

extension Localizeable {
    
    public func buildLocalizedString() throws -> String {
        guard let format = DELocalize(self.locKey) else {
            throw DEDetailedError.invalidLocalizationKey(self.locKey)
        }
        return String(format: format, self.locArgs)
    }
    
}
