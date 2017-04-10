//
//  DEGroupContainerItemRepresenter+SharedDialogs.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 07/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation


public class AppSharedDialogListRepresenter: DEGroupContainerItemRepresenter<AppSharedDialogList> {
    
    override init(item: DEGroupContainerItem,
                  encoder: DEGroupContainerItemDataEncoder<AppSharedDialogList> = DEProtobufItemDataEncoder.init()) {
        super.init(item: item, encoder: encoder)
    }
}


public class AppSharedDialogListContextItemRepresenter: DEGroupContainerItemRepresenter<AppSharedDialogListContext> {
    
    override init(item: DEGroupContainerItem,
                  encoder: DEGroupContainerItemDataEncoder<AppSharedDialogListContext> = DEProtobufItemDataEncoder.init()) {
        super.init(item: item, encoder: encoder)
    }
}
