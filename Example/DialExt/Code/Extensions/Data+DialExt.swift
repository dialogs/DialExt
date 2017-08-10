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
    
    // TODO: move to DialExt
    var md5: Data {
        var result = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        _ = result.withUnsafeMutableBytes {resultPtr in
            self.withUnsafeBytes {(bytes: UnsafePointer<UInt8>) in
                CC_MD5(bytes, CC_LONG(count), resultPtr)
            }
        }
        return result
    }
    
    var md5String: String {
        return self.md5.binaryString
    }
}
