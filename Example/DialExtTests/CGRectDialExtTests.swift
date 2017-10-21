//
//  CGRectDialExtTests.swift
//  DialExtTests
//
//  Created by Aleksei Gordeev on 21/10/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest

class CGRectDialExtTests: XCTestCase {
    
    func testSimpleItemPositioning() {
        let width: CGFloat = 100.0
        let insets = UIEdgeInsets.init(top: 25.0, left: 25.0, bottom: 25.0, right: 25.0)
        let rects = CGRect.rectsOf(itemWithInsets: insets,
                                   boxWidth: width,
                                   extendsBoxWidthToContainer: false,
                                   alignment: .left) { (width) -> (CGSize) in
                                    return CGSize(width: width, height: width)
        }
        
        let expectedBoxRect = CGRect.init(x: 0.0, y: 0.0, width: 100.0, height: 100.0)
        let expectedItemRect = CGRect.init(x: 25.0, y: 25.0, width: 50.0, height: 50.0)
        
        XCTAssertEqual(rects.box, expectedBoxRect)
        XCTAssertEqual(rects.item, expectedItemRect)
    }
    
    func testConstantItemPositioning() {
        let width: CGFloat = 100.0
        let insets = UIEdgeInsets.init(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        let rects = CGRect.rectsOf(itemWithInsets: insets, boxWidth: width, extendsBoxWidthToContainer: false, alignment: .left) { (width) -> (CGSize) in
            return CGSize.init(width: 10.0, height: 10.0)
        }
        let expectedBoxRect = CGRect.init(x: 0.0, y: 0.0, width: 30.0, height: 30.0)
        let expectedItemRect = CGRect.init(x: 10.0, y: 10.0, width: 10.0, height: 10.0)
        
        XCTAssertEqual(expectedBoxRect, rects.box)
        XCTAssertEqual(expectedItemRect, rects.item)
    }
    
    func testCenteredItemPositioning() {
        let insets = UIEdgeInsets.init(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        let rects = CGRect.rectsOf(itemWithInsets: insets, boxWidth: 100.0, extendsBoxWidthToContainer: false, alignment: .center) { (width) -> (CGSize) in
            return CGSize.init(width: 20.0, height: 20.0)
        }
        
        let expectedBoxRect = CGRect.init(x: 30.0, y: 0.0, width: 40.0, height: 40.0)
        let expectedItemRect = CGRect.init(x: 40.0, y: 10.0, width: 20.0, height: 20.0)
        
        XCTAssertEqual(rects.box, expectedBoxRect)
        XCTAssertEqual(rects.item, expectedItemRect)
    }
}
