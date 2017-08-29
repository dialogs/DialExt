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
    
    struct RectAdjustingTask {
        let original: CGRect
        let insets: UIEdgeInsets
        let expected: CGRect
    }
    
    func testRectAdjustingByInsets() {
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
    
    
    
}
