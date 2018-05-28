//
//  DEVersionComparator.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 28/05/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation

public final class DEVersionComparator {
    
    public init() {
        // do nothing
    }
    
    public func compare(_ version1: String, version2: String, comparator: String = ".") -> ComparisonResult {
        
        var ver1Comps = version1.components(separatedBy: comparator)
        var ver2Comps = version2.components(separatedBy: comparator)
       
        self.equalizeLengths(version1Components: &ver1Comps, version2Components: &ver2Comps)
        
        let length = ver1Comps.count
        
        guard length > 0 else {
            return .orderedSame
        }
        
        for i in 0..<length {
            let component1 = ver1Comps[i]
            let component2 = ver2Comps[i]
            
            let result = component1.compare(component2, options: .numeric)
            if result != .orderedSame {
                return result
            }
        }
        
        return .orderedSame
    }
    
    private func equalizeLengths(version1Components: inout [String], version2Components: inout [String]) {
        
        let componentsDiff = version1Components.count - version2Components.count
        let zeroComponents = [String].init(repeating: "0", count: abs(componentsDiff))
        
        if componentsDiff > 0 {
            version2Components.append(contentsOf: zeroComponents)
        }
        else {
            version1Components.append(contentsOf: zeroComponents)
        }
        
    }
    
}
