//
//  DialogListContext+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 15/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension DialogListContext {
    static public func createEmptyContext() -> DialogListContext {
        let contextBuilder = DialogListContext.getBuilder()
        contextBuilder.dialog = []
        contextBuilder.user = []
        let context = try! contextBuilder.build()
        return context
    }
}
