//
//  URLComponents+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 14/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension URLComponents {
    
    mutating public func updateQueryItems(emptyIfNil: Bool = true, code: ((inout [URLQueryItem]) -> ()) ) {
        var items = self.queryItems
        if emptyIfNil && items == nil {
            items = []
        }
        
        guard var sourceItems = items else {
            return
        }
        
        code(&sourceItems)
        self.queryItems = sourceItems
    }
}
