//
//  DialogListContext+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 15/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import SwiftProtobuf

public extension AppSharedDialogListContext {
    static public let empty: AppSharedDialogListContext = {
        return AppSharedDialogListContext.with({
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
}

public extension AppSharedDialogList {
    static public let empty: AppSharedDialogList = {
        return AppSharedDialogList.with({
            $0.ids = []
        })
    }()
}
