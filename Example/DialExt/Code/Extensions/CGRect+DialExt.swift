//
//  CGRect+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 21/10/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension CGRect {
    
    public func offsetFrom(originOfRect rect: CGRect) -> CGRect {
        return self.offsetFrom(point: rect.origin)
    }
    
    public func offsetFrom(point: CGPoint) -> CGRect {
        return self.offsetBy(dx: point.x, dy: point.y)
    }
    
    public func offsetBy(offset: UIOffset) -> CGRect {
        return self.offsetBy(dx: offset.horizontal, dy: offset.vertical)
    }

}

