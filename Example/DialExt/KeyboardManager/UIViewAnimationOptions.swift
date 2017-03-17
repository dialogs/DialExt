//  Copyright © 2016 Aleksei Gordeev. All rights reserved.

import UIKit

extension UIViewAnimationOptions {
    
    static var curveOptionsMap: [UIViewAnimationCurve : UIViewAnimationOptions] {
        return [
            .linear : .curveLinear,
            .easeIn : .curveEaseIn,
            .easeOut : .curveEaseOut,
            .easeInOut : .curveEaseInOut
        ]
    }
    
    /// Returns first found animation curve option element
    var animationCurve: UIViewAnimationCurve? {
        set {
            deleteAnimationCurveElements()
            if let animationCurve = animationCurve {
                let optionsItem = UIViewAnimationOptions.curveOptionsMap[animationCurve]!
                insert(optionsItem)
            }
        }
        
        get {
            let orderedElements = UIViewAnimationOptions.curveOptionsMap.values.sorted(by: {
                return $0.rawValue > $1.rawValue
            })
            
            var foundElement: UIViewAnimationOptions?
            for element in orderedElements {
                if self.contains(element) {
                    foundElement = element
                    break
                }
            }
            
            var curve: UIViewAnimationCurve? = nil
            if let foundElement = foundElement {
                let entry = UIViewAnimationOptions.curveOptionsMap.first { (key, value) -> Bool in
                    return value == foundElement
                    }!
                curve = entry.key
            }
            return curve
        }
    }
    
    mutating func deleteAnimationCurveElements() {
        for element in UIViewAnimationOptions.curveOptionsMap.values {
            self.remove(element)
        }
    }
}
