//
//  NSExtensionItem+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 20/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import MobileCoreServices

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
    
    public var sharingUrl: SharingURL? {
        if let attributedText = self.attributedContentText,
            let url = URL.init(string: attributedText.string)  {
            return SharingURL.init(url: url, attributedString: attributedText)
        }
        return nil
    }
    
    public func attachmentsWithTypeIdentifier(_ id: String) -> [NSItemProvider] {
        guard let attachments = self.attachments else {
            return []
        }
        return attachments.flatMap({
            guard let item = $0 as? NSItemProvider else {
                return nil
            }
            if item.hasItemConformingToTypeIdentifier(id) {
                return item
            }
            return nil
        })
    }
    
    public var videoAttachments: [NSItemProvider] {
        return self.attachmentsWithTypeIdentifier(kUTTypeMovie as String)
    }
    
    public var imageAttachments: [NSItemProvider] {
        return self.attachmentsWithTypeIdentifier(kUTTypeImage as String)
    }
    
    public var audioAttachments: [NSItemProvider] {
        return self.attachmentsWithTypeIdentifier(kUTTypeAudio as String)
    }
    
}
