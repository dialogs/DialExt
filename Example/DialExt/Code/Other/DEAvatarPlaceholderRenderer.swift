//
//  DEAvatarPlaceholderRenderer.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 16/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation 

/// You can subclass this class and implement your own renderer with advanced features
open class DEAvatarPlaceholderConfig {
    
    public var context: Context
    
    public var placeholder: String? = nil
    
    public struct Context {
        public var graphicsContext: CGContext
        public var size = CGSize(width: 44.0, height: 44.0)
        public var isCanceled: (() -> Bool)? = nil
    }
    
    public init(context: Context) {
        self.context = context
    }
    
}

/// Supposed to be thread safe
public protocol DEAvatarPlaceholderRendererable {
    func render(config: DEAvatarPlaceholderConfig)
}

public class DEAvatarPlaceholderRenderer: DEAvatarPlaceholderRendererable {
    
    public var borderWidth: CGFloat = 1 / UIScreen.main.scale * 2
    
    public func render(config: DEAvatarPlaceholderConfig) {
        renderBackground(config: config)
        renderBorder(config: config)
        renderTitle(config: config)
    }
    
    public func placeholderAttributesForConfig(_ config: DEAvatarPlaceholderConfig) -> [String : Any] {
        let font = UIFont.systemFont(ofSize: config.context.size.width / 2.0)
        
        let style : NSMutableParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        style.alignment = NSTextAlignment.center
        style.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        let attributes: [String : Any] = [
            NSParagraphStyleAttributeName: style,
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: UIColor.black
        ]
        
        return attributes
    }
    
    private func renderBackground(config: DEAvatarPlaceholderConfig) {
        let context = config.context.graphicsContext
        context.setFillColor(UIColor.white.cgColor)
        let backgroundRect = CGRect(origin: .zero, size: config.context.size).insetBy(dx: borderWidth,
                                                                                      dy: borderWidth).integral
        context.addEllipse(in: backgroundRect)
        context.drawPath(using: .fill)
    }
    
    private func renderBorder(config: DEAvatarPlaceholderConfig) {
        let context = config.context.graphicsContext
        
        let borderRect = CGRect(origin: .zero, size: config.context.size).insetBy(dx: borderWidth,
                                                                                  dy: borderWidth)
        
        context.setStrokeColor(UIColor(red: 0, green: 0, blue: 0, alpha: 0x10/255.0).cgColor)
        
        context.setLineWidth(borderWidth)
        
        context.addEllipse(in: borderRect)
        context.drawPath(using: .stroke)
    }
    
    private func renderTitle(config: DEAvatarPlaceholderConfig) {
        if let title = config.placeholder {
            let attributes = self.placeholderAttributesForConfig(config)
            var rect = CGRect(origin: .zero, size: config.context.size)
            
            let font = attributes[NSFontAttributeName]! as! UIFont
            let expectedHeight = font.lineHeight
            rect.origin.y = round(rect.midY - (expectedHeight / 2.0) )
            title.draw(in: rect, withAttributes: attributes)
        }
    }
}
