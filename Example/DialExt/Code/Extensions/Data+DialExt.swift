//
//  Data+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 25/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension Data {
    public var hexString: String {
        return self.map({String(format: "%02hhx", $0)}).joined()
    }
}
