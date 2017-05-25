//
//  CGSizeDialExtTests.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 22/05/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest

class CGSizeDialExtTests: XCTestCase {
    
    func testInitWithSide() {
        
        let side1 = CGFloat(100.0)
        let size1 = CGSize.init(side:side1)
        
        let side2 = Double(110.0)
        let size2 = CGSize.init(side: side2)
        
        let side3 = CGFloat(1000)
        let size3 = CGSize.init(side: side3)
        
        let side4 = -500.0
        let size4 = CGSize.init(side: side4)
        
        XCTAssertTrue(size1.width == side1 && size1.height == side1)
        XCTAssertTrue(size2.width == CGFloat(side2) && size2.height == CGFloat(side2))
        XCTAssertTrue(size3.width == side3 && size3.height == side3)
        XCTAssertTrue(Double(size4.width) == side4 && Double(size4.height) == side4)
    }
    
    func testRatio() {
        // MARK: Given & When
        let size1 = CGSize(width: 100.0, height: 100.0)
        let expectedRatio1: CGFloat = 1.0
        
        let size2 = CGSize(width: 4.0, height: 8.0)
        let expectedRatio2: CGFloat = 1/2.0
        
        let size3 = CGSize(width: 10.0, height: 3.0)
        let expectedRatio3: CGFloat = 10.0/3.0
        
        XCTAssertEqual(size1.ratio, expectedRatio1)
        XCTAssertEqual(size2.ratio, expectedRatio2)
        XCTAssertEqual(size3.ratio, expectedRatio3)
    }
    
    func testLimitedSizeThatIsUnderLimit() {
        let size = CGSize(width: 100.0, height: 100.0)
        let limitedSize = size.limited(bySquare: 1000000000.0)
        XCTAssertEqual(size, limitedSize)
    }
    
    func testLimitedSize() {
        
        let size = CGSize(width: 100.0, height: 100.0)
        let limit: CGFloat = 100.0
        
        let limitedSize = size.limited(bySquare: limit)
        
        let expectedSize = CGSize(width: 10.0, height: 10.0)
        XCTAssertEqual(limitedSize, expectedSize)
    }
    
    func testLimitedRoundedSize() {
        let size = CGSize(width: 44.5, height: 44.5)
        let limit: CGFloat = 1089
        let limitedSize = size.limited(bySquare: limit)
        let roundedLimitedSize = limitedSize.rounded()
        
        let expectedSize = CGSize(width: 33, height: 33)
        XCTAssertEqual(roundedLimitedSize, expectedSize)
    }
    
    func testLimitedSizeKeepsRatio() {
        let size1 = CGSize(width: 100.0, height: 100.0)
        let limitedSize1 = size1.limited(bySquare: 100.0)
        
        XCTAssertEqual(size1.ratio, limitedSize1.ratio)
    }
    
}
