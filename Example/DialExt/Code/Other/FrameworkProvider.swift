//
//  FrameworkProvider.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 16/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension Bundle {

    public static let dialExtBundle: Bundle = {
        return DialExtFramework.bundle
    }()
    
}

fileprivate class DialExtFramework: NSObject {
    
    fileprivate static let bundle: Bundle = {
       return detectBundle()
    }()
    
    private static func detectBundle() -> Bundle {
        return Bundle(for: self)
    }
    
}
