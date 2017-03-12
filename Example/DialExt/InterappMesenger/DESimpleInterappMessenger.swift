//
//  DESimpleInterappMessenger.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 10/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public typealias DESimpleInterappMessengerMessage = Dictionary<String, Any>

public class DESimpleInterappMessenger: DEInterappMessenger<DESimpleInterappMessengerMessage> {
    
    init(sharedItem: DEGroupContainerItem) {
        let encoder = Encoder.init()
        super.init(sharedItem: sharedItem, encoder: encoder)
    }
    
    private class Encoder: DEInterappMessengeEncoder<DESimpleInterappMessengerMessage> {
        
        override func encode(message: DESimpleInterappMessengerMessage) throws -> Data {
            return try PropertyListSerialization.data(fromPropertyList: message, format: .binary, options: 0)
        }
        
        override func decode(data: Data) throws -> DESimpleInterappMessengerMessage {
            return try PropertyListSerialization.propertyList(from: data, options: .init(rawValue: 0), format: nil) as! DESimpleInterappMessengerMessage
        }
    }
}
