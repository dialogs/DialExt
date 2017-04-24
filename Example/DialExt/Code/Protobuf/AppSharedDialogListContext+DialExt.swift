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
        let contextBuilder = AppSharedDialogListContext.getBuilder()
        contextBuilder.dialogs = []
        contextBuilder.users = []
        /*
         let user: AppSharedUser = {
         let builder = AppSharedUser.getBuilder()
         builder.name = "Me"
         builder.id = 123456
         return try! builder.build()
         }()
         
         contextBuilder.mainUser = user
         */
        let context = try! contextBuilder.build()
        return context
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
}

public extension AppSharedDialogList {
    static public let empty: AppSharedDialogList = {
        let builder = AppSharedDialogList.getBuilder()
        builder.ids = []
        return try! builder.build()
    }()
}

public extension AppSharedDialogListContext.Builder {
    
    public func setCurrentVersion() {
        self.version = AppSharedDialogListContext.version
    }
    
}
