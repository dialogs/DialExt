//
//  DEGroupContainerItemDataEncoder.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 13/12/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation


open class DEGroupContainerItemDataEncoder<Representation> {
    
    open func decode(data: Data) throws -> Representation {
        fatalError("Should be implemented in subclass")
    }
    
    open func encode(representation: Representation) throws -> Data {
        fatalError("Should be implemented in subclass")
    }
    
    public init() {
        
    }
    
}


public final class DEGroupContainerItemStringEncoder: DEGroupContainerItemDataEncoder<String> {
    
    public var encoding: String.Encoding = .utf8
    
    public override func decode(data: Data) throws -> String {
        guard let string = String.init(data: data, encoding: self.encoding) else {
            throw NSError.unknown(domain: "im.dlg.encoding", userInfo: nil)
        }
        return string
    }
    public override func encode(representation: String) throws -> Data {
        guard let data = representation.data(using: self.encoding) else {
            throw NSError.unknown(domain: "im.dlg.encoding", userInfo: nil)
        }
        return data
    }
    
}

