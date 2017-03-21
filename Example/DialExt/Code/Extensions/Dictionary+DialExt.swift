//
//  Dictionary+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 10/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

extension Dictionary {
    mutating func de_merge(with dictionary: Dictionary) {
        for (key, value) in dictionary {
            self.updateValue(value, forKey: key)
        }
    }
}
