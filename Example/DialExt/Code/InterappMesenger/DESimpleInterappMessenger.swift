//
//  DESimpleInterappMessenger.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 10/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public typealias DESimpleInterappMessengerMessage = Dictionary<String, Any>

typealias DESimpleInterappMessenger = DEInterappMessenger<DESimpleInterappMessengerMessage>

extension DEInterappMessenger {
    static func createSimpleMessenger(sharedItem: DEGroupContainerItem) -> DESimpleInterappMessenger {
        let encoder = DESimpleMessageEncoder.init()
        let messenger = DESimpleInterappMessenger.init(sharedItem: sharedItem, encoder: encoder)
        return messenger
    }
}

public class DESimpleMessageEncoder: DEInterappMessageEncoder<DESimpleInterappMessengerMessage> {
    
    public override init() {
        super.init()
    }
    
    override func encode(message: DESimpleInterappMessengerMessage) throws -> Data {
        return try PropertyListSerialization.data(fromPropertyList: message, format: .binary, options: 0)
    }
    
    override func decode(data: Data) throws -> DESimpleInterappMessengerMessage {
        return try PropertyListSerialization.propertyList(from: data, options: .init(rawValue: 0), format: nil) as! DESimpleInterappMessengerMessage
    }
}
 
