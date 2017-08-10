//
//  NSLayoutConstraint+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 03/05/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

extension NSLayoutConstraint {
    
    public class func de_wrappingView(_ view: UIView,
                                      bindToTopLayoutGuide: UILayoutSupport? = nil,
                                      bindToBottomLayoutGuide: UILayoutSupport? = nil,
                                      insets: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
        
        let viewName = "view"
        let viewsInfo = [viewName: view]
        let metrics = [
            "left" : insets.left,
            "right" : insets.right,
            "top" : insets.top,
            "bottom": insets.bottom
        ]
        
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-left-[\(viewName)]-right-|", options: [], metrics: metrics, views: viewsInfo)
        
        var verticalConstraints: [NSLayoutConstraint] = []
        if let guide = bindToTopLayoutGuide {
            let constraint = NSLayoutConstraint.init(item: view, attribute: .top, relatedBy: .equal,
                                                     toItem: guide, attribute: .bottom, multiplier: 1.0,
                                                     constant: insets.top)
            verticalConstraints.append(constraint)
        }
        else {
            let constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-top-[\(viewName)]",
                metrics: metrics,
                views: viewsInfo)
            verticalConstraints.append(contentsOf: constraints)
        }
        
        if let guide = bindToBottomLayoutGuide {
            let constraint = NSLayoutConstraint.init(item: view, attribute: .bottom, relatedBy: .equal,
                                                     toItem: guide, attribute: .top, multiplier: 1.0,
                                                     constant: insets.bottom)
            verticalConstraints.append(constraint)
        }
        else {
            let constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[\(viewName)]-bottom-|",
                metrics: metrics,
                views: viewsInfo)
            verticalConstraints.append(contentsOf: constraints)
        }
        
        
        let constraints = horizontalConstraints + verticalConstraints
        return constraints
    }
}

public extension Array where Element == NSLayoutConstraint {
    public func activate() {
        NSLayoutConstraint.activate(self)
    }
}
