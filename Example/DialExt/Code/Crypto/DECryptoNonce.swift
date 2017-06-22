//
//  DEInt64BasedNonce.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 21/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

/**
 Nonce is wrapped Int64 value, providing bytes order converting and data representation routine
*/
public struct DEInt64BasedNonce: Comparable {
    
    public static let nonceDataLength = 24
    
    /// value in bigEndianEncoding
    public var value: Int64
    
    public var nonce: Data {
        return CFByteOrderGetCurrent() == OSLittleEndian ? littleEndianData : bigEndianData
    }
    
    public var littleEndianData: Data {
        var data = Data.de_withValue(self.value.littleEndian)
        data.appendByZeros(toLength: DEInt64BasedNonce.nonceDataLength)
        return data
    }
    
    public var bigEndianData: Data {
        var data = Data.de_withValue(self.value.bigEndian)
        data.appendByZeros(toLength: DEInt64BasedNonce.nonceDataLength)
        return data
    }
    
    public init(value: Int64) {
        self.value = value
    }
    
    public init(bigEndianValue: Int64) {
        self.init(value: Int64.init(bigEndian: bigEndianValue))
    }
    
    public init(littleEndianValue: Int64) {
        self.init(value: Int64.init(littleEndian: littleEndianValue))
    }
    
    public init(data: Data) {
        let value: Int64 = data.de_toValue()
        self.init(value: value)
    }
    
    public static func ==(lhs: DEInt64BasedNonce, rhs: DEInt64BasedNonce) -> Bool {
        return lhs.value == rhs.value
    }
    
    public static func <(lhs: DEInt64BasedNonce, rhs: DEInt64BasedNonce) -> Bool {
        return lhs.value < rhs.value
    }
}
