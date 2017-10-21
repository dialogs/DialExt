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
    
    public enum ContentAlignment: Int {
        case left
        case center
        case right
    }
    
    public static func rectsOf(itemWithInsets insets: UIEdgeInsets,
                               boxWidth: CGFloat,
                               extendsBoxWidthToContainer: Bool = false,
                               alignment: ContentAlignment = .left,
                               calculator: ((CGFloat)->(CGSize))) -> (box: CGRect, item: CGRect) {
        let availableWidth = boxWidth - insets.horizontalSum
        let itemSize = calculator(availableWidth)
        
        let boxSize: CGSize
        if extendsBoxWidthToContainer {
            boxSize = CGSize(width: boxWidth, height: itemSize.height + insets.verticalSum)
        }
        else {
            boxSize = CGSize(width: itemSize.width + insets.horizontalSum,
                             height: itemSize.height + insets.verticalSum)
        }
        
        let itemY = insets.top
        let boxX: CGFloat
        switch alignment {
        case .left: boxX = 0.0
        case .center: boxX = (boxWidth - boxSize.width) / 2.0
        case .right: boxX = boxWidth - boxSize.width
        }
        
        let itemOrigin = CGPoint(x: boxX + insets.left, y: itemY)
        let itemRect = CGRect(origin: itemOrigin, size: itemSize)
        
        let boxRect = CGRect(origin: CGPoint(x: boxX, y: 0.0), size: boxSize)
        return (boxRect, itemRect)
    }
    
}

