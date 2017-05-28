//
//  DEUploadIntegerSize.swift
//  Pods
//
//  Created by Aleksei Gordeev on 27/05/2017.
//
//

import Foundation


public struct DEUploadIntegerSize: Hashable {
    
    public var width: Int
    public var height: Int
    
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
    
    public init(width: CGFloat, height: CGFloat) {
        self.width = Int(width)
        self.height = Int(height)
    }
    
    public init(size: CGSize) {
        self.init(width: size.width, height: size.height)
    }
    
    public static func ==(lhs: DEUploadIntegerSize, rhs: DEUploadIntegerSize) -> Bool {
        return (lhs.width == rhs.width &&
            lhs.height == rhs.height)
    }
    
    public var hashValue: Int {
        return self.width ^ self.height
    }
}

