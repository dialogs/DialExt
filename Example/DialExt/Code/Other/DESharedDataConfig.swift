//
//  DESharedDataConfig.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 18/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public struct DESharedDataConfig {
    
    /// Provide one of the values from "Capabilities -> Keychain Sharing" by prefixing it with your app id prefix (from dev portal).
    /// So, if keychain group is "my.keychain.group" and app id prefix is "123A4567B8", target value is "123A4567B8.my.keychain.group"
    let keychainGroup: String
    
    /// Provide one of the values from "Capabilities -> AppGroups" as is.
    let appGroup: String
    
    /// Should contain at least one endpoint supporting file uploading.
    let endpointUploadMethodURLs: [URL]
    
    public init(keychainGroup: String, appGroup: String, uploadURLs: [URL]) {
        self.keychainGroup = keychainGroup
        self.appGroup = appGroup
        self.endpointUploadMethodURLs = uploadURLs
    }
    
}
