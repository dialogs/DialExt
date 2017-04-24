//
//  LimitedValueType.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 24/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public struct LimitedValueType<T: Comparable> {
    
    public let minValue: T?
    
    public let maxValue: T?
    
    public var value: T {
        set {
            setupValue(newValue)
        }
        
        get {
            return fixedValue
        }
    }
    
    public var fixedValue: T
    
    public init(value: T, minValue: T? = nil, maxValue: T? = nil) {
        self.minValue = minValue
        self.maxValue = maxValue
        self.fixedValue = type(of: self).fixedValue(value, minValue: minValue, maxValue: maxValue)
    }
    
    private mutating func setupValue(_ value: T) {
        self.fixedValue = type(of: self).fixedValue(value, minValue: self.minValue, maxValue: self.maxValue)
    }
    
    private static func fixedValue(_ value: T, minValue: T?, maxValue: T?) -> T {
        var targetValue = value
        if let minV = minValue {
            targetValue = max(targetValue, minV)
        }
        if let maxV = maxValue {
            targetValue = min(targetValue, maxV)
        }
        return targetValue
    }
    
}
