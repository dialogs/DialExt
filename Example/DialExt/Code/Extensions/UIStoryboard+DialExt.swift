//
//  UIStoryboard+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 19/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

extension UIStoryboard {
    class func loadIfExist(name: String, from bundle: Bundle?) -> Self? {
        let bundle = bundle ?? Bundle.main
        return loadFirstFound(name: name, bundles: [bundle])
    }
    
    class func loadFirstFound(name: String, bundles: [Bundle]) -> Self? {
        let bundle = bundles.first(where: { $0.hasStoryboard(named: name )})
        return bundle != nil ? self.init(name: name, bundle: bundle) : nil
    }
}
