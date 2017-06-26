//
//  DEGroupContainerItemRepresenter+SharedDialogs.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 07/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

import SwiftProtobuf


public class DEProtobufContainerItemRepresenter<Proto: Message>: DEGroupContainerItemRepresenter<Proto> {
    
    public class func createDefaultEncoder() -> DEGroupContainerItemDataEncoder<Proto> {
        return DEProtobufItemDataEncoder<Proto>.init()
    }
    
    public init(item: DEGroupContainerItem) {
        super.init(item: item, encoder: type(of: self).createDefaultEncoder())
    }
    
}

public class DEProtobufContainterItemBindedRepresenter<Proto: Message>: DEGroupContainerItemBindedRepresenter<Proto> {
    
    init(item: DEGroupContainerItem) {
        let representer = DEProtobufContainerItemRepresenter<Proto>.init(item: item)
        super.init(unbindableRepresenter: representer, storePolicy: .onSuccessOnly)
    }
}

public typealias AppSharedDialogListBindedRepresenter = DEProtobufContainterItemBindedRepresenter<AppSharedDialogList>

public typealias AppSharedDialogListContextBindedRepresenter = DEProtobufContainterItemBindedRepresenter<AppSharedDialogListContext>
