//
//  CGSize+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 22/05/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension CGSize {
    
    public init(side: CGFloat) {
        self.init(width: side, height: side)
    }
    
    public init(side: Double) {
        self.init(width: side, height: side)
    }
    
    
    public var square: CGFloat {
        return self.width * self.height
    }
    
    public var perimeter: CGFloat {
        return self.width + self.height
    }
    
    /// Proportional relationship between image's width and height.
    public var ratio: CGFloat {
        return self.width / self.height
    }
    
    public func multiplied(by multiplier: CGFloat) -> CGSize {
        return CGSize(width: self.width * multiplier, height : self.height * multiplier)
    }
    
    /**
     * Returns size proportionaly scaled by difference between limit and size's square.
     * Returns unchanges size if it's under the limit.
     */
    public func limited(bySquare limit: CGFloat) -> CGSize {
        let square = self.square
        guard square > limit else {
            return self
        }
        
        let limitMultiplier: CGFloat = (limit / self.square).squareRoot()
        return self.multiplied(by: limitMultiplier)
    }
    
    /**
     * Returns size proportionaly scaled by difference between original and limit sides.
     * Returns unchanges size if it's under the limit.
     */
    public func limited(bySize: CGSize) -> CGSize {
        fatalError()
    }
    
    // TODO: Implement limited(bySide limit: CGFloat, proportionally: Bool = false) -> CGSize
    
    public func rounded(rule: FloatingPointRoundingRule = .down) -> CGSize {
        return CGSize(width: self.width.rounded(rule), height: self.height.rounded(rule))
    }
    
    public func pointsSize(rounded rule: FloatingPointRoundingRule = .down) -> (width: Int, height: Int) {
        let width = Int(self.width.rounded(rule))
        let height = Int(self.height.rounded(rule))
        return (width, height)
    }
    
}
