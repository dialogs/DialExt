//
//  DataDialExtTests.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 20/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
import DialExt

class DataDialExtTests: XCTestCase {
    
    func testIntToData() {
        let ints: [Int] = [1, 2, 3, 101, 505, 707, -10100, 0, Int.max, Int.min]
        ints.forEach { (int) in
            let data = Data.de_withValue(int)
            let decodedInt: Int = data.de_toValue()
            XCTAssertEqual(int, decodedInt)
        }
    }
    
    
    func testInt64ToData() {
        let ints: [Int64] = [1, 2, 3, 101, 505, 707, -10100, 0, Int64(Int.max), Int64(Int.min), Int64.max, Int64.min]
        ints.forEach { (int) in
            let data = Data.de_withValue(int)
            let decodedInt: Int64 = data.de_toValue()
            XCTAssertEqual(int, decodedInt)
        }
    }
//    
//    func testIntToDataHex() {
//        let nonce: Int64 = Int64(-2622849142741802).bigEndian
//        var data = Data.de_withValue(nonce)
//        data.appendByZeros(toLength: 24)
//        XCTAssertEqual(data.de_hexString, "fff6ae88588c24d600000000000000000000000000000000")
//    }
//    
//    func testDataHexToInt() {
//        let string = "fff6ae88588c24d600000000000000000000000000000000"
//        let data = string.de_encoding(.hex)!
//        let nonce: Int64 = data.de_toValue()
//        XCTAssertEqual(nonce, Int64(-2622849142741802).bigEndian)
//    }
    
}
