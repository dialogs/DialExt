//
//  DEInt64BasedNonceTests.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 21/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
import DialExt

class DEInt64BasedNonceTests: XCTestCase {
    
    public var nonceValue: Int64 = -2622849142741802
    
    func testNonceLittleEndianCreation() {
        let nonce = DEInt64BasedNonce.init(self.nonceValue)
        XCTAssertEqual(nonce.value, self.nonceValue)
    }
    
    func testNonceBigEndianCreation() {
        let bigEndianNonceValue = self.nonceValue.bigEndian
        let nonce = DEInt64BasedNonce.init(bigEndianValue: bigEndianNonceValue)
        XCTAssertEqual(nonce.value, self.nonceValue)
    }
    
    func testNonceEquataion() {
        let nonce1 = DEInt64BasedNonce.init(self.nonceValue)
        let nonce2 = DEInt64BasedNonce.init(self.nonceValue)
        let nonce3 = DEInt64BasedNonce.init(bigEndianValue: self.nonceValue.bigEndian)
        XCTAssertEqual(nonce1, nonce2)
        XCTAssertEqual(nonce2, nonce3)
        XCTAssertEqual(nonce3, nonce1)
    }
    
    func testNonceComparison() {
        let nonce1 = DEInt64BasedNonce.init(self.nonceValue)
        let nonce2 = DEInt64BasedNonce.init(bigEndianValue: (self.nonceValue + 1).bigEndian)
        let nonce3 = DEInt64BasedNonce.init(self.nonceValue + 2)
        let nonce4 = DEInt64BasedNonce.init(bigEndianValue: (self.nonceValue + 3).bigEndian)
        
        XCTAssertEqual(nonce1, nonce1)
        XCTAssertLessThan(nonce1, nonce2)
        XCTAssertLessThan(nonce1, nonce3)
        XCTAssertLessThan(nonce1, nonce4)
        
        XCTAssertGreaterThan(nonce2, nonce1)
        XCTAssertEqual(nonce2, nonce2)
        XCTAssertLessThan(nonce2, nonce3)
        XCTAssertLessThan(nonce2, nonce4)
        
        XCTAssertGreaterThan(nonce3, nonce1)
        XCTAssertGreaterThan(nonce3, nonce2)
        XCTAssertEqual(nonce3, nonce3)
        XCTAssertLessThan(nonce3, nonce4)
        
        XCTAssertGreaterThan(nonce4, nonce1)
        XCTAssertGreaterThan(nonce4, nonce2)
        XCTAssertGreaterThan(nonce4, nonce3)
        XCTAssertEqual(nonce4, nonce4)
    }
    
    func testLittleEndianDataRepresentation() {
        let nonce1 = DEInt64BasedNonce.init(self.nonceValue)
        let data = nonce1.nonce
        let decodedValue: Int64 = data.de_toValue()
        XCTAssertEqual(self.nonceValue, decodedValue)
    }
    
    func testBigEndianDataRepresentation() {
        let bigEndianNonceValue = self.nonceValue.bigEndian
        let nonce1 = DEInt64BasedNonce.init(bigEndianValue: bigEndianNonceValue)
        let data = nonce1.nonce
        let decodedValue: Int64 = data.de_toValue()
        XCTAssertEqual(self.nonceValue, decodedValue)
    }
    
    func testDifferentByteOrderNonces() {
        let nonceValue = self.nonceValue
        let littleEndianNonceValue = self.nonceValue.littleEndian
        let bigEndianNonceValue = self.nonceValue.bigEndian
        
        let nonce = DEInt64BasedNonce.init(nonceValue)
        let littleEndianBasedNonce = DEInt64BasedNonce.init(littleEndianValue: littleEndianNonceValue)
        let bigEndianBasedNonce = DEInt64BasedNonce.init(bigEndianValue: bigEndianNonceValue)
        
        XCTAssertEqual(nonce, littleEndianBasedNonce)
        XCTAssertEqual(nonce, bigEndianBasedNonce)
        XCTAssertEqual(littleEndianBasedNonce, bigEndianBasedNonce)
    }
    
    func testDifferentByteOrderNonceDatas() {
        let nonceValue = self.nonceValue
        let littleEndianNonceValue = self.nonceValue.littleEndian
        let bigEndianNonceValue = self.nonceValue.bigEndian
        
        let nonce = DEInt64BasedNonce.init(nonceValue)
        let littleEndianBasedNonce = DEInt64BasedNonce.init(littleEndianValue: littleEndianNonceValue)
        let bigEndianBasedNonce = DEInt64BasedNonce.init(bigEndianValue: bigEndianNonceValue)
        
        XCTAssertEqual(nonce.nonce, littleEndianBasedNonce.nonce)
        XCTAssertEqual(nonce.nonce, bigEndianBasedNonce.nonce)
        XCTAssertEqual(littleEndianBasedNonce.nonce, bigEndianBasedNonce.nonce)
    }
    
    func testDifferentByteOrderNonceBigEndianValuesDatas() {
        let nonceValue = self.nonceValue
        let littleEndianNonceValue = self.nonceValue.littleEndian
        let bigEndianNonceValue = self.nonceValue.bigEndian
        
        let nonce = DEInt64BasedNonce.init(nonceValue)
        let littleEndianBasedNonce = DEInt64BasedNonce.init(littleEndianValue: littleEndianNonceValue)
        let bigEndianBasedNonce = DEInt64BasedNonce.init(bigEndianValue: bigEndianNonceValue)
        
        XCTAssertEqual(nonce.bigEndianData, littleEndianBasedNonce.bigEndianData)
        XCTAssertEqual(nonce.bigEndianData, bigEndianBasedNonce.bigEndianData)
        XCTAssertEqual(littleEndianBasedNonce.bigEndianData, bigEndianBasedNonce.bigEndianData)
    }
}
