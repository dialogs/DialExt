//
//  Label.swift
//  DialogSDK
//
//  Created by Aleksei Gordeev on 06/12/2016.
//  Copyright © 2016 Dialog LLC. All rights reserved.
//

import Foundation

fileprivate var handlerAssociatedObjectKey: String = "im.de.dialog.button_touchup_handler"


extension UIButton {
    
    public func setupEdgeInsets(contentEdgePaddings: CGFloat, imageToTitlePadding: CGFloat) {
        var contentInsets = self.contentEdgeInsets
        contentInsets.left = contentEdgePaddings
        contentInsets.right = contentEdgePaddings
        
        var imageInsets = self.imageEdgeInsets
        imageInsets.left = -imageToTitlePadding * 2
        
        contentInsets.left += imageToTitlePadding
        
        self.contentEdgeInsets = contentInsets
        self.imageEdgeInsets = imageInsets
    }
    
    public typealias DETouchUpInsideCallback = ((UIButton) -> ())
    
    public class DETouchUpInsideHandler: NSObject {
        let callback: DETouchUpInsideCallback
        
        public init(callback: @escaping DETouchUpInsideCallback) {
            self.callback = callback
        }
    }
    
    var de_touchUpInsideHandler: DETouchUpInsideHandler? {
        set {
            let selector = #selector(de_onTouchUpInside(sender:))
            if newValue == nil {
                removeTarget(self, action: selector, for: .touchUpInside)
            }
            else {
                addTarget(self, action: selector, for: .touchUpInside)
            }
            objc_setAssociatedObject(self,
                                     &handlerAssociatedObjectKey,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        get {
            return objc_getAssociatedObject(self, &handlerAssociatedObjectKey) as? DETouchUpInsideHandler
        }
    }
    
    public func de_setTouchUpInsideHandler(ifNilOnly: Bool = false, callback: @escaping DETouchUpInsideCallback) {
        let shouldLeftOldHandler = ifNilOnly && self.de_touchUpInsideHandler != nil
        guard !shouldLeftOldHandler else { return }
        
        self.de_touchUpInsideHandler = DETouchUpInsideHandler.init(callback: callback)
    }
    
    @objc private func de_onTouchUpInside(sender: UIButton) {
        self.de_touchUpInsideHandler?.callback(sender)
    }
    
}
