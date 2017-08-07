//
//  Dialog+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 15/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation


public extension AppSharedUser {
    public static func create(_ block: (AppSharedUser.Builder) -> ()) -> AppSharedUser {
        let builder = AppSharedUser.Builder.init()
        block(builder)
        return try! builder.build()
    }
}


public extension AppSharedDialog {
    
    public static func create(_ block: (AppSharedDialog.Builder) -> ()) -> AppSharedDialog {
        let builder = AppSharedDialog.Builder.init()
        block(builder)
        return try! builder.build()
    }
    
    public typealias Id = Int64
    
    public static func avatarSharedItemName(for dialog: AppSharedDialog) -> String {
        return self.avatarSharedItemName(for: dialog.id, isGroup: dialog.isGroup)
    }
    
    public static func avatarSharedItemName(for dialogId: Id, isGroup: Bool) -> String {
        let prefix = isGroup ? "g" : "u"
        let name = "\(prefix)\(dialogId)"
        return name
    }
    
    public var avatarSharedItemName: String {
        return AppSharedDialog.avatarSharedItemName(for: self)
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
