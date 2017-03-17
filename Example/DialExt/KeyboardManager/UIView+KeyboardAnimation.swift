//  Copyright © 2016 Aleksei Gordeev. All rights reserved.

import UIKit


public extension UIView {
    
    /**
     Attempts to synchronize your UI changes with keyboard event.
     Do changes immediately for 'did'-happens events.
     
     - parameter event: source event to get animation info from.
     - parameter options: desired animation options. 'Curve' will be overwriten.
     - paramater animations: block with UI changes to animate.
     - parameter completion: block closure to be executed when the animation sequence ends. This block has no return value and takes a single Boolean argument that indicates whether or not the animations actually finished before the completion handler was called.
     */
    public class func animateKeyboardEvent(_ event: KeyboardEvent,
                                           options: UIViewAnimationOptions = [],
                                           animations: @escaping () -> Swift.Void,
                                           completion: ((Bool) -> Swift.Void)? = nil) {
        let duration = event.type.isKindOfDidEvent() ? 0.0 : event.animationDuration
        var eventOptions = options
        eventOptions.animationCurve = event.animationCurve
        eventOptions.insert(.beginFromCurrentState)
        
        self.animate(withDuration: duration,
                     delay: 0.0,
                     options: eventOptions,
                     animations:animations,
                     completion: completion)
    }
    
    public func animateKeyboardEvent(_ event: KeyboardEvent,
                                     bottomConstraint: NSLayoutConstraint,
                                     options: UIViewAnimationOptions = [],
                                     completion:  ((Bool) -> Swift.Void)? = nil) {
        let keyboardFrame = event.endFrame(for: self)
        let offset = max(self.bounds.intersection(keyboardFrame).height, 0.0)
        UIView.animateKeyboardEvent(event, options: options, animations: { 
            bottomConstraint.constant = offset
            self.superview?.layoutIfNeeded()
        }, completion: completion)
    }
}
