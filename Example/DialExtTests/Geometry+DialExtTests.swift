//
//  Geometry+DialExtTests.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 29/08/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest

@testable import DialExt

class Geometry_DialExtTests: XCTestCase {
    
    func testRectAdjustingByInsets() {
        
        struct RectAdjustingTask {
            let original: CGRect
            let insets: UIEdgeInsets
            let expected: CGRect
        }
        
        let tasks: [RectAdjustingTask] = [
            
            RectAdjustingTask.init(original: .init(x: -1.0, y: -1.0, width: 101.0, height: 101.0),
                                   insets: .init(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0),
                                   expected: .init(origin: .zero, size: .init(side: 99.0))),
            
            RectAdjustingTask.init(original: .init(x: 100.0, y: 100.0, width: 16.0, height: 16.0),
                                   insets: .init(top: 0.0, left: 0.0, bottom: 1.0, right: 1.0),
                                   expected: .init(x: 100.0, y: 100.0, width: 15.0, height: 15.0)),
            
            RectAdjustingTask.init(original: .init(x: 5.0, y: 5.0, width: 99.0, height: 99.0),
                                   insets: .init(top: 3.0, left: 5.0, bottom: 2.0, right: 4.0),
                                   expected: .init(x: 10.0, y: 8.0, width: 90.0, height: 94.0))
        ]
        
        for task in tasks {
            XCTAssertEqual(task.original.adjusting(insets: task.insets), task.expected)
        }
        
    }
    
    func testEdgeInsetsInit() {
        
        struct EdgeInsetsInitTask {
            let original: UIEdgeInsets
            let expected: UIEdgeInsets
        }
        
        let tasks: [EdgeInsetsInitTask] = [
            EdgeInsetsInitTask.init(original: .init(horizontal: 10.0, vertical: 10.0),
                                    expected: .init(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)),
            
            EdgeInsetsInitTask.init(original: .init(horizontal: 5.0, vertical: 8.0),
                                    expected: .init(top: 8.0, left: 5.0, bottom: 8.0, right: 5.0)),
            
            EdgeInsetsInitTask.init(original: .init(horizontal: -100.0, vertical: -83.0),
                                    expected: .init(top: -83.0, left: -100.0, bottom: -83.0, right: -100.0))
        ]
        
        for task in tasks {
            XCTAssertEqual(task.original, task.expected)
        }
    }
    
    func testMidYReset() {
        let rect1 = CGRect.init(origin: .init(x: 10.0, y: 10.0), size: .init(side: 10.0))
        let originalRect = CGRect.init(origin: .init(x: 0.0, y: 0.0), size: .init(side: 20.0))
        
        var modifiedRect = originalRect
        modifiedRect.resetMidY(rect: rect1)
        
        XCTAssertEqual(modifiedRect.size, originalRect.size)
        XCTAssertEqual(modifiedRect.origin.x, originalRect.origin.x)
        
        XCTAssertEqual(modifiedRect.midY, rect1.midY)
        
        XCTAssertEqual(modifiedRect.origin.y, 5.0)
    }
    
    func testMidXReset() {
        let rect1 = CGRect.init(origin: .init(x: 10.0, y: 10.0), size: .init(side: 10.0))
        let originalRect = CGRect.init(origin: .init(x: 0.0, y: 0.0), size: .init(side: 20.0))
        
        var modifiedRect = originalRect
        modifiedRect.resetMidX(rect: rect1)
        
        XCTAssertEqual(modifiedRect.size, originalRect.size)
        XCTAssertEqual(modifiedRect.origin.y, originalRect.origin.y)
        
        XCTAssertEqual(modifiedRect.midX, rect1.midX)
        
        XCTAssertEqual(modifiedRect.origin.x, 5.0)
    }

    
    func testEdgeInsetsSideSum() {
        
        struct EdgeInsetsSideSumTask {
            let original: UIEdgeInsets
            let expectedVerSum: CGFloat
            let expectedHorSum: CGFloat
        }
        
        let tasks: [EdgeInsetsSideSumTask] = [
            EdgeInsetsSideSumTask.init(original: .zero,
                                       expectedVerSum: 0.0,
                                       expectedHorSum: 0.0),
            
            EdgeInsetsSideSumTask.init(original: .init(top: 0.0, left: 2.0, bottom: 0.0, right: 2.0),
                                       expectedVerSum: 0.0, expectedHorSum: 4.0),
            
            EdgeInsetsSideSumTask.init(original: .init(top: 4.0, left: 0.0, bottom: 9.0, right: 0.0),
                                       expectedVerSum: 13.0, expectedHorSum: 0.0),
            
            EdgeInsetsSideSumTask.init(original: .init(top: 111.3, left: 35.0, bottom: 112.0, right: 54.4),
                                       expectedVerSum: 223.3, expectedHorSum: 89.4),
            
            EdgeInsetsSideSumTask.init(original: .init(top: -100.0, left: -50.0, bottom: -4.0, right: -23.0),
                                       expectedVerSum: -104.0, expectedHorSum: -73.0)
        ]
        
        for task in tasks {
            XCTAssertEqual(task.original.horizontalSum, task.expectedHorSum)
            XCTAssertEqual(task.original.verticalSum, task.expectedVerSum)
        }
    }
    
}
