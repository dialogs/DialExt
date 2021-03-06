//
//  UIImage+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 22/05/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import MobileCoreServices

public enum DEImageRepresentationType: Int {
    
    case jpeg
    
    case png
    
    case gif
    
    case tiff
    
    var utiType: String {
        switch self {
        case .gif:
            return kUTTypeGIF as String
        case .png:
            return kUTTypePNG as String
        case .tiff:
            return kUTTypeTIFF as String
        case .jpeg:
            return kUTTypeJPEG as String
        }
    }
}

public extension Data {
    
    // returns image type if data representing an image with known type
    public var de_representationType: DEImageRepresentationType? {
        
        guard !self.isEmpty, self.count >= 1 else {
            return nil
        }
        
        let type = self.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> DEImageRepresentationType? in
            let bytes = ptr.pointee
            switch bytes {
            case 0xFF:
                return DEImageRepresentationType.jpeg
            case 0x89:
                return DEImageRepresentationType.png
            case 0x47:
                return DEImageRepresentationType.gif
            case 0x49, 0x4D:
                return DEImageRepresentationType.tiff
            default:
                return nil
            }
        }
        return type
    }
    
}

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
        return Int(self.pixelSize.square)
    }
    
    public func limited(byPixelsCount limit: Int) -> UIImage {
        let originalPixelsCount = self.pixelsCount
        guard originalPixelsCount > limit else {
            return self
        }
        
        let limitedSize = self.pixelSize.limited(bySquare: CGFloat(limit)).rounded()
        let image = self.resized(size: limitedSize, scale: 1.0)
        
        if image.pixelsCount > limit {
            print("Fail to generate limited pixels image.")
        }
        
        return image
    }
    
    public func limited(bySize limitSize: CGSize) -> UIImage {
        let realSize = self.pixelSize
        let factor = min(limitSize.width / realSize.width, limitSize.height / realSize.height)
        if factor < 1.0 {
            let targetSize = realSize.multiplied(by: factor)
            return self.resized(size: targetSize, scale: 1.0)
        }
        else {
            return self
        }
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
