//  Copyright © 2016 Aleksei Gordeev. All rights reserved.

import UIKit

public struct KeyboardEvent: Equatable {
    
    enum EventType {
        case willShow
        case didShow
        case willHide
        case didHide
        
        func isKindOfDidEvent() -> Bool {
            return (self == .didShow || self == .didHide)
        }
        
        func isKindOfWillEvent() -> Bool {
            return !isKindOfDidEvent()
        }
    }
    
    var type = EventType.willShow
    
    var beginFrame = CGRect.zero
    var endFrame = CGRect.zero
    
    /// Supposed to be linear for 'did'-happens events
    var animationCurve = UIViewAnimationCurve.linear
    
    /// Supposed to be '0.0' for 'did'-happens events
    var animationDuration: TimeInterval = 0.0
    
    var isLocal: Bool = false
    
    func beginFrame(for view: UIView) -> CGRect {
        return view.convert(beginFrame, from: nil)
    }
    
    func endFrame(for view: UIView) -> CGRect {
        return view.convert(endFrame, from: nil)
    }
}

public func == (lhs: KeyboardEvent, rhs: KeyboardEvent) -> Bool {
    return (lhs.type == rhs.type &&
        lhs.beginFrame == rhs.endFrame &&
        lhs.endFrame == rhs.endFrame &&
        lhs.animationCurve == rhs.animationCurve &&
        lhs.animationDuration == rhs.animationDuration &&
        lhs.isLocal == rhs.isLocal)
}
