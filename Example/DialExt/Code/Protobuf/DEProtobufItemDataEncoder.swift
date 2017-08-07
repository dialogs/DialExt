//
//  DEProtobufItemDataEncoder.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 10/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

import ProtocolBuffers



public class DEProtobufItemDataEncoder<ProtoType>: DEGroupContainerItemDataEncoder<ProtoType> where ProtoType: GeneratedMessage {
    override public func encode(representation: ProtoType) throws -> Data {
        return try representation.toJSON()
    }
    
    override public func decode(data: Data) throws -> ProtoType {
        return try ProtoType.fromJSON(data: data)
    }
}
