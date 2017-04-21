//
//  NSExtensionItem+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 20/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension NSExtensionItem {
    
    public var firstFoundDataRepresentableAttachment: NSItemProvider? {
        
        guard let attachments = self.attachments else {
            return nil
        }
        
        for case let attachment as NSItemProvider in attachments {
            if attachment.isDataRepresentable {
                return attachment
            }
        }
        
        return nil
    }
    
}
