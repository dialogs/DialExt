//
//  DialogListContext+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 15/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension AppSharedDialogListContext {
    static public let empty: AppSharedDialogListContext = {
        return AppSharedDialogListContext.create({
            $0.dialogs = []
            $0.users = []
        })
    }()
    
    static public let version: String = {
        let bundle = Bundle.dialExtBundle
        let url = bundle.url(forResource: "dialog", withExtension: "proto")!
        let file = try! String(contentsOf: url)
        let lines = file.components(separatedBy: .newlines)
        let versionMark = "[Version] = "
        let versionLine = lines.first(where: { $0.contains(versionMark) })!
        let versionLineComponents = versionLine.components(separatedBy: .whitespaces)
        let version = versionLineComponents.last!
        return version
    }()
    
    static public func create(_ block: (AppSharedDialogListContext.Builder) -> ()) -> AppSharedDialogListContext {
        let builder = AppSharedDialogListContext.Builder.init()
        block(builder)
        return try! builder.build()
    }
}

public extension AppSharedDialogList {
    
    static public func create(_ block: (AppSharedDialogList.Builder) -> ()) -> AppSharedDialogList {
        let builder = AppSharedDialogList.Builder.init()
        block(builder)
        return try! builder.build()
    }
    
    static public let empty: AppSharedDialogList = {
        return AppSharedDialogList.create({
            $0.ids = []
        })
    }()
}
