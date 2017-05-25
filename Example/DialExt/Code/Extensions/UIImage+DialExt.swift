//
//  UIImage+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 22/05/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension UIImage {
    
    public static let defaultPixelsCountLimit: CGFloat = 1200.0 * 1200.0
    
    public var pixelSize: CGSize {
        if self.scale != 1.0 {
            return self.size
        }
        
        var size = self.size
        size.width *= self.scale
        size.height *= self.scale
        return size
    }
    
    public var pixelsCount: Int {
        return Int(self.pixelSize.perimeter)
    }
    
    public func limited(byPixelsCount limit: Int) -> UIImage {
        let originalPixelsCount = self.pixelsCount
        guard originalPixelsCount > limit else {
            return self
        }
        
        let limitedSize = self.pixelSize.limited(bySquare: CGFloat(limit)).rounded()
        let image = self.resized(size: limitedSize, scale: 1.0)
        
        if image.pixelsCount > limit {
            print("Fail to generate limited pixels image. ")
        }
        
        return image
    }
    
    public func resized(size: CGSize, scale: CGFloat = 0.0) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        
        // Legacy code. Have no idea, what is the point of negative offset and increasing size.
        var drawSize = size
        drawSize.width += 2.0
        drawSize.height += 2.0
        let drawRect = CGRect(origin: CGPoint(x: -1, y: -1), size: drawSize)
        
        draw(in: drawRect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    /// Creates context with main screen scale and size of image, performs code and returns image from context.
    public func drawInImageSizedContext(scale: CGFloat? = nil, code: (() -> ())) -> UIImage {
        let targetScale = scale ?? 0.0
        
        // 0.0 is for main screen scale.
        UIGraphicsBeginImageContextWithOptions(self.size, false, targetScale)
        
        code()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
}
