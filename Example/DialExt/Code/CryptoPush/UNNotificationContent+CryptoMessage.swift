//
//  UNNotificationContent+CryptoMessage.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 27/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import UserNotifications

@available(iOSApplicationExtension 10.0, *) internal extension UNNotificationContent {
    
    var encryptedAlertData: Data? {
        return self.userInfo["encryptedData"] as? Data
    }
    
    var encryptedAlertNonce: DEInt64BasedNonce? {
        guard let nonceValue = self.userInfo["nonce"] as? Int64 else {
            return nil
        }
        return DEInt64BasedNonce.init(nonceValue)
    }
    
}

