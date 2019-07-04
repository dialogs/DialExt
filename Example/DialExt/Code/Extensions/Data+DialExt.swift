//
//  Data+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 25/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import CommonCrypto

public extension Data {
    
    private static let deHexStringRegex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
    
    public var de_hexString: String {
        return self.map({String(format: "%02hhx", $0)}).joined()
    }
    
    public static func de_withHexString(_ string: String) -> Data? {
        return string.de_encoding(.hex)
    }
    
    public var digestSHA1: Data {
        var bytes: [UInt8] = Array(repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        
        withUnsafeBytes {
            _ = CC_SHA1($0, CC_LONG(count), &bytes)
        }
        
        return Data(bytes: bytes)
    }
    
    mutating func appendByZeros(toLength length: Int) {
        let padding = length - self.count
        guard padding > 0 else {
            return
        }
        let tail = Data.init(repeating: 0, count: padding)
        self.append(tail)
    }
    
    public static func de_withValue<Value>(_ value: Value) -> Data {
        var inoutValue = value
        return withUnsafePointer(to: &inoutValue, {
            return Data(buffer: UnsafeBufferPointer(start: $0, count: 1))
        })
    }
    
    public func de_toValue<Value>() -> Value {
        return self.withUnsafeBytes { (ptr: UnsafePointer<Value>) -> Value in
            return ptr.pointee
        }
    }
    
    var crc32: UInt32 {
        let crc = CRC32.init(data: self)
        return crc.crc
    }
    
}

extension Data {
    
    public var toBytes: Array<UInt8> {
        return [UInt8](self)
    }
    
}

extension Collection where Element == UInt8 {
    
    public var toData: Data {
        return Data(bytes: self)
    }
    
}
