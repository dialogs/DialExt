//
//  Data+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 25/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension Data {
    public var hexString: String {
        return self.map({String(format: "%02hhx", $0)}).joined()
    }
    
    public static func de_withValue<Value>(_ value: Value) -> Data {
        var inoutValue = value
        return withUnsafePointer(to: &inoutValue, {
            return Data(buffer: UnsafeBufferPointer(start: $0, count: MemoryLayout<Value>.size))
        })
    }
    
    public func de_toValue<Value>() -> Value {
        return self.withUnsafeBytes { (ptr: UnsafePointer<Value>) -> Value in
            return ptr.pointee
        }
    }
    
}
