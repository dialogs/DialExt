//
//  Error+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 11/12/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension NSError {
    
    public static func unknown(domain: String = NSCocoaErrorDomain, userInfo: [String : Any]? = nil) -> Error {
        return NSError.init(domain: domain, code: NSURLErrorUnknown, userInfo: userInfo)
    }
    
    
}
