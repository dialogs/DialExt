//
//  String+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 17/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension String {
    
    public mutating func append(byNewLines count: Int = 1) {
        let newLines = String(repeating: "\r\n", count: count)
        self.append(newLines)
    }
    
    public func appending(byNewLines count: Int = 1) -> String {
        var string = self
        string.append(byNewLines: count)
        return string
    }
    
}
