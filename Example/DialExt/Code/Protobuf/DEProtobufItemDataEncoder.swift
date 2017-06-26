//
//  DEProtobufItemDataEncoder.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 10/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

import SwiftProtobuf


public class DEProtobufItemDataEncoder<ProtoType>: DEGroupContainerItemDataEncoder<ProtoType> where ProtoType: Message {
    override public func encode(representation: ProtoType) throws -> Data {
        return try representation.serializedData()
    }
    
    override public func decode(data: Data) throws -> ProtoType {
        return try ProtoType.init(serializedData: data)
    }
}
