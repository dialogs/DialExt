//
//  AlertingPush+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 27/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import UserNotifications

extension AlertingPush {
    
    func supposeTitle() throws -> String {
        guard let title = self.alertTitle else {
            throw DEEncryptedPushNotificationError.noAlertDataTitle
        }
        
        switch title {
        case let .locAlertTitle(localizable): return try localizable.buildLocalizedString()
        case let .simpleAlertTitle(text): return text
        }
    }
    
    
    func supposeBody() throws -> String {
        guard let body = self.alertBody else {
            throw DEEncryptedPushNotificationError.noAlertDataBody
        }
        
        switch body {
        case let .locAlertBody(localizable): return try localizable.buildLocalizedString()
        case let .simpleAlertBody(text): return text
        }
    }
    
    @available(iOSApplicationExtension 10.0, *) func supposeSound() -> UNNotificationSound {
        let soundName = self.sound
        return soundName.isEmpty ? UNNotificationSound.default() : UNNotificationSound.init(named: soundName)
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
