//
//  DEAvatarImageProvider.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 16/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public typealias DEAvatarImageProviderCompletion = ((UIImage?, Bool) -> ())

public protocol DEAvatarImageProvidable {
    func provideImage(dialog: AppSharedDialog, completion: @escaping DEAvatarImageProviderCompletion)
}

public class DEAvatarImageProvider: DEAvatarImageProvidable {
    
    private typealias AvatarCache = NSCache<NSString, UIImage>
    
    private let cache: AvatarCache = {
        let cache = AvatarCache.init()
        cache.countLimit = 100
        return cache
    }()
    
    public private(set) var localLoader: DESharedAvatarLoader
    
    public private(set) var placeholderRenderer: DEAvatarPlaceholderRendererable? = nil
    
    public func provideImage(dialog: AppSharedDialog, completion: @escaping DEAvatarImageProviderCompletion) {
        self.localLoader.load(dialog: dialog) { (result) in
            switch result {
            case let .loaded(image): completion(image, false)
            default: self.requestPlaceholder(dialog: dialog, completion: completion)
            }
        }
    }
    
    public func requestPlaceholder(dialog: AppSharedDialog, completion: @escaping DEAvatarImageProviderCompletion) {
        guard let renderer = self.placeholderRenderer else {
            completion(nil, true)
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let size = CGSize(width: 44.0, height: 44.0)
            UIGraphicsBeginImageContextWithOptions(size,
                                                   false,
                                                   UIScreen.main.scale)
            let graphicsContext = UIGraphicsGetCurrentContext()!
            let placeholderContext = DEAvatarPlaceholderConfig.Context(graphicsContext: graphicsContext,
                                                                       size: size,
                                                                       isCanceled: nil)
            let config = DEAvatarPlaceholderConfig(context: placeholderContext)
            config.placeholder = dialog.placeholderTitle
            
            renderer.render(config: config)
            
            let image = UIGraphicsGetImageFromCurrentImageContext()!
            
            DispatchQueue.main.async {
                completion(image, false)
            }
        }
    }
    
    public init(localLoader: DESharedAvatarLoader,
                renderer: DEAvatarPlaceholderRendererable? = DEAvatarPlaceholderRenderer.init()) {
        self.localLoader = localLoader
        self.placeholderRenderer = renderer
    }
}
