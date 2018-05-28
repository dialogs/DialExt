//
//  NotificationContentRequiredUpdateExtractor.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 28/05/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import UserNotifications


public final class NotificationContentRequiredUpdateExtractor {
    
    public init() {
        // do nothing
    }
    
    public func execute(content: UNNotificationContent) -> ReqUpdate? {
        return self.execute(contentUserInfo: content.userInfo)
    }
    
    public func execute(contentUserInfo: [AnyHashable:Any]) -> ReqUpdate? {
        
        guard let minVersionObj = contentUserInfo["req_upd_min_ver"], let minVersion = minVersionObj as? String else {
            return nil
        }
        
        let updateTemplate = ReqUpdate.Builder.init()
        updateTemplate.minVersion = minVersion
        
        if let linkObj = contentUserInfo["req_upd_link"], let link = linkObj as? String {
            updateTemplate.appLink = link
        }
        
        do {
            let update = try updateTemplate.build()
            return update
        }
        catch {
            DESErrorLog("Fail to build required update instance")
            return nil
        }
    }
    
}
