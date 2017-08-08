//
//  DEKeychainQuery+Shared.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 10/07/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension DEKeychainQuery.Access {

    public static let defaultSharedAccount = "im.dlg.shared"
    
    public static func shared(_ access: DEKeychainQuery.Service, group: String? = nil) -> DEKeychainQuery.Access {
        return self.init(access, account: self.defaultSharedAccount, group: group)
    }
    
}

public extension DEKeychainQuery {
    
    public static func readShared(_ service: DEKeychainQuery.Service) -> DEKeychainQuery {
        return self.init(access: .shared(service), operation: .read(config: nil))
    }
    
    public static func writeShared(_ service: DEKeychainQuery.Service, data: NSData) -> DEKeychainQuery {
        return self.init(access: .shared(service), operation: .add(value: data))
    }
    
    public static func deleteShared(_ service: DEKeychainQuery.Service) -> DEKeychainQuery {
        return self.init(access: .shared(service), operation: .delete)
    }
    
}
