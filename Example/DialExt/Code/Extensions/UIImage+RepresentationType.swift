//
//  UIImage+RepresentationType.swift
//  DialExt
//
//  Created by Lex on 06/12/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
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

