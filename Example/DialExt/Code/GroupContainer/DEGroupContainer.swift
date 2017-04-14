//
//  DEGroupContainer.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 10/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation


public class DEGroupContainer {
    
    public let groupId: String
    
    private lazy var containerUrl: URL = {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: self.groupId) else {
            fatalError("Could not find container for group '\(self.groupId)'. Please, check your entitlements.")
        }
        return url
    }()
    
    public init(groupId: String) {
        self.groupId = groupId
    }
    
    public func item(forFileNamed name: String, callbackQueue: DispatchQueue = .main) -> DEGroupContainerItem {
        let fileUrl = self.containerUrl.appendingPathComponent(name)
        let presenter = DEGroupContainerFilePresenter.init(url: fileUrl)
        presenter.callbackQueue = callbackQueue
        return presenter
    }
    
}
