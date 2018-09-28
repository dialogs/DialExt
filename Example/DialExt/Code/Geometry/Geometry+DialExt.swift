//
//  Geometry+DialExt.swift
//  Pods
//
//  Created by Aleksei Gordeev on 09/06/2017.
//
//

import Foundation

extension CGRect {
    
    /// Change size by applying new maxX
    public mutating func resize(maxX: CGFloat) {
        self = self.resized(maxX: maxX)
    }
    
    public func resized(maxX: CGFloat) -> CGRect {
        let difference = maxX - self.maxX
        guard difference < 0.0 else {
            return self
        }
        return CGRect.init(origin: self.origin,
                           size: CGSize(width: self.size.width + difference, height: self.size.height))
    }
    
    public func adjusting(insets: UIEdgeInsets) -> CGRect {
        return UIEdgeInsetsInsetRect(self, insets)
    }
    
    public func originX(centeredWidth: CGFloat) -> CGFloat {
        return self.minX + (self.size.width - centeredWidth) / 2.0
    }
    
    public func originY(centeredHeight: CGFloat) -> CGFloat {
        return self.minY + (self.size.height - centeredHeight) / 2.0
    }
    
    public var topHalfRect: CGRect {
        return CGRect(origin: self.origin, size: CGSize(width: self.size.width, height: self.size.height / 2.0))
    }
    
    public var bottomHalfRect: CGRect {
        return self.adjusting(insets: .init(top: self.size.height / 2.0, left: 0.0, bottom: 0.0, right: 0.0))
    }
    
    public func resettingMidY(rect: CGRect) -> CGRect {
        var newRect = self
        newRect.resetMidY(rect: rect)
        return newRect
    }
    
    mutating public func resetMidY(rect: CGRect) {
        self.origin.y = rect.origin.y - (self.size.height - rect.size.height) / 2.0
    }
    
    public func resettingMidX(rect: CGRect) -> CGRect {
        var newRect = self
        newRect.resetMidX(rect: rect)
        return newRect
    }
    
    mutating public func resetMidX(rect: CGRect) {
        self.origin.x = rect.origin.x - (self.size.width - rect.size.width) / 2.0
    }
    
    public func verticalPositionedSubrects(count: Int) -> [CGRect] {
        guard count > 1 else {
            return [self]
        }
        var rects: [CGRect] = []
        let height = self.size.height / CGFloat(count)
        for idx in 0..<count {
            let origin = CGPoint(x: self.minX, y: self.minY + CGFloat(idx) * height)
            let rect = CGRect(origin: origin, size: CGSize(width: self.size.width, height: height))
            rects.append(rect)
        }
        return rects
    }
    
    public func subrect(size: CGSize, position: Position = .none, alignment: CenterAlignment = .all, limited: Bool = true) -> CGRect {
        
        let rectToPlace: CGRect
        
        var targetSize = size
        
        switch position {
        case .topHalf: rectToPlace = self.topHalfRect
        case .bottomHalf: rectToPlace = self.bottomHalfRect
        case .none: rectToPlace = self
        }
        
        if limited {
            targetSize = CGSize(width: min(targetSize.width, rectToPlace.size.width),
                                height: min(targetSize.height, rectToPlace.size.height))
        }
        
        var origin = self.origin
        if alignment.contains(.horizontal) {
            origin.x = rectToPlace.originX(centeredWidth: targetSize.width)
        }
        if alignment.contains(.vertical) {
            origin.y = rectToPlace.originY(centeredHeight: targetSize.height)
        }
        
        return CGRect(origin: origin, size: targetSize)
    }
    
    public enum Position: Int {
        
        /**
         Positioning element supposed to be placed just in the center of rect
         */
        case none
        
        
        /**
         Positioning element supposed to be placed in top half aread
         
         ```
         ------------
         |          |
         | element  |   - Top half.
         |          |
         ------------
         |          |
         |          |   - Bottom half
         |          |
         ------------
         ```
         */
        case topHalf
        
        /**
         Positioning element supposed to be placed in top half aread
         
         ```
         ------------
         |          |
         |          |   - Top half.
         |          |
         ------------
         |          |
         | element  |   - Bottom half
         |          |
         ------------
         ```
         */
        case bottomHalf
    }
    
    
    public struct CenterAlignment: OptionSet {
        
        public let rawValue: Int

        public typealias RawValue = Int
        
        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
        
        public static let horizontal = CenterAlignment(rawValue: 1 << 0)
        
        public static let vertical = CenterAlignment(rawValue: 1 << 1)
        
        public static let all: CenterAlignment = [.horizontal, .vertical]
    }
    
}

public extension UIEdgeInsets {
    
    public init(horizontal: CGFloat, vertical: CGFloat) {
        self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
    
    public var horizontalSum: CGFloat {
        return self.left + self.right
    }
    
    public var verticalSum: CGFloat {
        return self.top + self.bottom
    }
    
    public var startPoint: CGPoint {
        return CGPoint(x: self.left, y: self.top)
    }
}
