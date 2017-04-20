//
//  FrameworkProvider.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 16/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension Bundle {

    public static let dialExtBundle: Bundle = DialExtFramework.bundle
    
    public static let dialExtResourcesBundle: Bundle = DialExtFramework.resourcesBundle
    
}

fileprivate class DialExtFramework: NSObject {
    
    fileprivate static let bundle: Bundle = {
       return detectBundle()
    }()
    
    fileprivate static let resourcesBundle: Bundle = {
        return detectResoucesBundle()
    }()
    
    private static func detectBundle() -> Bundle {
        return Bundle(for: self)
    }
    
    private static func detectResoucesBundle() -> Bundle {
        let frameworkBundle = detectBundle()
        if let url = frameworkBundle.url(forResource: "DialExt", withExtension: "bundle") {
            return Bundle.init(url: url)!
        }
        return frameworkBundle
    }
    
}
