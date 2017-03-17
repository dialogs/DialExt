//
//  Dialog+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 15/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation


public extension Dialog {
    
    public typealias Id = Int64
    
    public var avatarSharedItemName: String {
        let prefix = self.isGroup ? "g" : "u"
        let name = "\(prefix)\(id)"
        return name
    }
    
    public var placeholderTitle: String {
        return constructPlaceholder()
    }
    
    public func constructPlaceholder(limit: Int = 2, capitalized: Bool = true) -> String {
        let whitespaces = CharacterSet.whitespacesAndNewlines
        let components = title.components(separatedBy: whitespaces)
        let maxCompontents = components.prefix(limit)
        let letters: [String] = maxCompontents.map({
            guard let letter = $0.characters.first else {
                return ""
            }
            let letterString = String([letter])
            return capitalized ? letterString.capitalized : letterString
        })
        
        return letters.joined()
    }
}
