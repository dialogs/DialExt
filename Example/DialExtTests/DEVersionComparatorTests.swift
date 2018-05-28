//
//  DEVersionComparatorTests.swift
//  DialExtTests
//
//  Created by Aleksei Gordeev on 28/05/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import DialExt

class DEVersionComparatorTests: XCTestCase {
    
    private var comparator: DEVersionComparator! = nil
    
    override func setUp() {
        super.setUp()
        
        self.comparator = DEVersionComparator.init()
    }
    
    func testSimpleVersion() {
        XCTAssertEqual(self.comparator.compare("1.0", version2: "1.0"), ComparisonResult.orderedSame)
    }
    
    func testEmpty() {
        XCTAssertEqual(self.comparator.compare("", version2: ""), ComparisonResult.orderedSame)
    }
    
    func testMinorAscending() {
        XCTAssertEqual(self.comparator.compare("1.0", version2: "1.1"), ComparisonResult.orderedAscending)
    }
    
    func testDiffLengthMinorAscending() {
        XCTAssertEqual(self.comparator.compare("1.0", version2: "1.0.1"), ComparisonResult.orderedAscending)
    }
    
    func testDiffLengthMinorDescending() {
        XCTAssertEqual(self.comparator.compare("2.0.33.44", version2: "2.0.33"), ComparisonResult.orderedDescending)
    }
    
    func testEmptyVersusLongVersion() {
        XCTAssertEqual(self.comparator.compare("", version2: "1.0.0.0.0.0"), ComparisonResult.orderedAscending)
    }
    
    func testDescending() {
        XCTAssertEqual(self.comparator.compare("3.0", version2: "2.0"), ComparisonResult.orderedDescending)
    }
    
}
