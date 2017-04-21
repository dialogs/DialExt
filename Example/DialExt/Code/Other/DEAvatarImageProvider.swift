//
//  DEAvatarImageProvider.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 16/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public typealias DEAvatarImageProviderCompletion = ((_ image: UIImage?, _ isPlaceholder: Bool) -> ())

public protocol DEAvatarImageProvidable {
    func provideImage(dialog: AppSharedDialog, completion: @escaping DEAvatarImageProviderCompletion) -> UIImage?
}

public extension DEAvatarPlaceholderRendererable {
    func renderAsync(workQueue: DispatchQueue = DispatchQueue.global(qos: .userInitiated),
                     callbackQueue: DispatchQueue = .main,
                     size: CGSize = CGSize(width: 44.0, height: 44.0),
                     dialog: AppSharedDialog,
                     completion: @escaping ((_ image: UIImage) -> ())) {
        workQueue.async {
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
            let graphicsContext = UIGraphicsGetCurrentContext()!
            let placeholderContext = DEAvatarPlaceholderConfig.Context(graphicsContext: graphicsContext,
                                                                       size: size,
                                                                       isCanceled: nil)
            let config = DEAvatarPlaceholderConfig(context: placeholderContext)
            config.placeholder = dialog.placeholderTitle
            
            self.render(config: config)
            
            let image = UIGraphicsGetImageFromCurrentImageContext()!
            
            UIGraphicsEndImageContext()
            
            callbackQueue.async {
                completion(image)
            }
        }
    }
}

public class DEDebugAvatarImageProvider: DEAvatarImageProvidable {
    
    private let placeholderRenderer = DEAvatarPlaceholderRenderer.init()
    
    public func provideImage(dialog: AppSharedDialog, completion: @escaping DEAvatarImageProviderCompletion) -> UIImage? {
        placeholderRenderer.renderAsync(dialog: dialog) { (image) in
            completion(image, true)
        }
        return nil
    }
    
    public init() {
        
    }
}

public class DEAvatarImageProvider: DEAvatarImageProvidable {
    
    private typealias AvatarCache = NSCache<NSNumber, UIImage>
    
    private let cache: AvatarCache = {
        let cache = AvatarCache.init()
        cache.countLimit = 100
        return cache
    }()
    
    public private(set) var localLoader: DESharedAvatarLoader
    
    public private(set) var placeholderRenderer: DEAvatarPlaceholderRendererable? = nil
    
    public func provideImage(dialog: AppSharedDialog, completion: @escaping DEAvatarImageProviderCompletion) -> UIImage? {
        if let image = self.cache.object(forKey: NSNumber.init(value: dialog.id)) {
            return image
        }
        
        self.localLoader.load(dialog: dialog) { (result) in
            switch result {
            case let .loaded(image): self.handleImageLoaded(image, dialog: dialog, isPlaceholder: false, completion: completion)
            default: self.requestPlaceholder(dialog: dialog, completion: completion)
            }
        }
        return nil
    }
    
    private func handleImageLoaded(_ image: UIImage,
                                  dialog: AppSharedDialog,
                                  isPlaceholder: Bool,
                                  completion: DEAvatarImageProviderCompletion) {
        self.cache.setObject(image, forKey: NSNumber.init(value: dialog.id))
        completion(image, isPlaceholder)
    }
    
    private func requestPlaceholder(dialog: AppSharedDialog, completion: @escaping DEAvatarImageProviderCompletion) {
        guard let renderer = self.placeholderRenderer else {
            completion(nil, false)
            return
        }
        
        renderer.renderAsync(dialog: dialog) { (image) in
            self.handleImageLoaded(image, dialog: dialog, isPlaceholder: true, completion: completion)
        }
    }
    
    public init(localLoader: DESharedAvatarLoader,
                renderer: DEAvatarPlaceholderRendererable? = DEAvatarPlaceholderRenderer.init()) {
        self.localLoader = localLoader
        self.placeholderRenderer = renderer
    }
}
