//
//  ShareViewController.swift
//  Share
//
//  Created by Aleksei Gordeev on 15/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import Social
import DialExt

public enum FakeError: Error {
    case noError
}


@objc(ShareViewController) class ShareViewController: DESharedDialogsPresentationViewController {
    
    override var config: DESharedDataConfig! {
        return DESharedDataConfig.init(keychainGroup: "", appGroup: "", uploadURLs: [])
    }
    
    override func configureDialogsViewController(_ viewController: DESharedDialogsViewController) {
        
        let container = DEDebugContainer.init()
        viewController.manager = DESharedDialogsManager.init(groupContainer: container, keychainGroup: "")
        
        viewController.avatarProvider = DEDebugAvatarImageProvider.init()
        
        // TODO: Provide debug uploade for testing UI responsiveness
//        viewController.uploader = DEExtensionItemUploader.init(fileUploader: debugFileUploader)
    }
}
