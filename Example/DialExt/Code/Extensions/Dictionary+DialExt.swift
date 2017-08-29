//
//  Dictionary+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 10/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension Dictionary {
    
    public mutating func de_merge(with dictionary: Dictionary) {
        for (key, value) in dictionary {
            self.updateValue(value, forKey: key)
        }
    }
    
    public func de_merging(dictionary: Dictionary) -> Dictionary {
        var mergedDictionary = self
        mergedDictionary.de_merge(with: dictionary)
        return mergedDictionary
    }
    
}
