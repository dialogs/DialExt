//
//  SharingURL.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 19/05/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public struct SharingURL: CustomStringConvertible {
    
    var url: URL
    
    var attributedString: NSAttributedString? = nil
    
    
    public init(url: URL, attributedString: NSAttributedString? = nil) {
        
        self.url = url
        
        self.attributedString = attributedString
    }
    
    public var description: String {
        if let string = self.attributedString {
            return string.string
        }
        return self.url.absoluteString
    }
}
