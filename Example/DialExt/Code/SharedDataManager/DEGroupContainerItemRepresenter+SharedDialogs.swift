//
//  DEGroupContainerItemRepresenter+SharedDialogs.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 07/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import ProtocolBuffers


public class DEProtobufContainerItemRepresenter<Proto: GeneratedMessageProtocol>: DEGroupContainerItemRepresenter<Proto> {
    
    public class func createDefaultEncoder() -> DEGroupContainerItemDataEncoder<Proto> {
        return DEProtobufItemDataEncoder<Proto>.init()
    }
    
    public init(item: DEGroupContainerItem) {
        super.init(item: item, encoder: type(of: self).createDefaultEncoder())
    }
    
}

public class DEProtobufContainerItemBindedRepresenter<Proto: GeneratedMessageProtocol>: DEGroupContainerItemBindedRepresenter<Proto> {
    
    init(item: DEGroupContainerItem) {
        let representer = DEProtobufContainerItemRepresenter<Proto>.init(item: item)
        super.init(unbindableRepresenter: representer, storePolicy: .onSuccessOnly)
    }
}

public typealias AppSharedDialogListBindedRepresenter = DEProtobufContainerItemBindedRepresenter<AppSharedDialogList>

public typealias AppSharedDialogListContextBindedRepresenter = DEProtobufContainerItemBindedRepresenter<AppSharedDialogListContext>
