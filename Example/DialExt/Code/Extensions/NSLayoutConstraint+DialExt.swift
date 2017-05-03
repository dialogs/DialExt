//
//  NSLayoutConstraint+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 03/05/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

extension NSLayoutConstraint {
    
    public class func de_wrappingView(_ view: UIView, insets: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
        
        let viewName = "view"
        let viewsInfo = [viewName: view]
        let metrics = [
            "left" : insets.left,
            "right" : insets.right,
            "top" : insets.top,
            "bottom": insets.bottom
        ]
        
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-left-[\(viewName)]-right-|", options: [], metrics: metrics, views: viewsInfo)
        
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-top-[\(viewName)]-bottom-|", options: [], metrics: metrics, views: viewsInfo)
        let constraints = horizontalConstraints + verticalConstraints
        return constraints
    }
    
}
