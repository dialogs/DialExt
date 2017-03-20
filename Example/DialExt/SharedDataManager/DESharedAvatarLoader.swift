//
//  DESharedAvatarLoader.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 16/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public class DESharedAvatarLoader {
    
    private typealias AvatarCache = NSCache<NSString, UIImage>
    
    public static func createWithContainerGroupId(_ id: String) -> DESharedAvatarLoader {
        return DESharedAvatarLoader.init(groupContainer: DEGroupContainer.init(groupId: id))
    }
    
    public typealias Completion = (Result) -> ()
    
    private let container: DEGroupContainer
    
    public enum Result {
        case notFound
        case loaded(UIImage)
        case failure(Error?)
    }
    
    public init(groupContainer: DEGroupContainer) {
        self.container = groupContainer
    }
    
    public func load(dialog: AppSharedDialog, completion: Completion?) {
        let filename = dialog.avatarSharedItemName
        let item = container.item(forFileNamed: filename)
        item.readData({ (fileData) in
            if let data = fileData, let image = UIImage(data: data) {
                completion?(.loaded(image))
            }
            else {
                completion?(.notFound)
            }
        }) { (error) in
            completion?(.failure(error))
        }
    }
}
