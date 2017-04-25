//  Copyright © 2016 Aleksei Gordeev. All rights reserved.

import UIKit

protocol KeyboardDetectorDelegate: class {
    func keyboardDetector(_ keyboardDetector:KeyboardDetector, detectEvent event:KeyboardEvent)
}

protocol KeyboardDetector: class {
    weak var delegate: KeyboardDetectorDelegate? {get set}
}


class NotificationBasedKeyboardDetector: KeyboardDetector {
    
    private var observers: [NSObjectProtocol]!
    
    weak var delegate: KeyboardDetectorDelegate?
    
    init() {
        subscribeToNotifications()
    }
    
    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Events
    
    func createEvent(type: KeyboardEvent.EventType, userInfo: NSDictionary) -> KeyboardEvent {
        var event = KeyboardEvent()
        
        event.type = type
        event.beginFrame = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        event.endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        if let curveValue = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber,
            let curve = UIViewAnimationCurve(rawValue: curveValue.intValue) {
            event.animationCurve = curve
        }
        
        if let animationDurationValue = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber {
            event.animationDuration = animationDurationValue.doubleValue as TimeInterval
        }
        
        if #available(iOS 9.0, *) {
            let isLocalValue = userInfo[UIKeyboardIsLocalUserInfoKey] as? NSNumber
            event.isLocal = (isLocalValue != nil) ? isLocalValue!.boolValue : false
        }
        
        return event
    }
    
    func sendEvent(type:KeyboardEvent.EventType, userInfo:NSDictionary) -> Void {
        let event = createEvent(type: type, userInfo:userInfo)
        self.delegate?.keyboardDetector(self, detectEvent: event)
    }
    
    // MARK: - Notifications
    
    func subscribeToNotifications() {
        let notificationCenter = NotificationCenter.default
        let queue = OperationQueue.main
        
        observers = [NSObjectProtocol]()
        
        var observer = notificationCenter.addObserver(forName: .UIKeyboardWillHide,
                                                      object: nil,
                                                      queue: queue) { [weak self] (notification) in
                                                        withExtendedLifetime(self, {
                                                            self!.handleWillHideNotification(notification: notification)
                                                        })
        }
        
        observers.append(observer)
        
        
        observer = notificationCenter.addObserver(forName: .UIKeyboardDidHide,
                                                  object: nil,
                                                  queue: queue) { [weak self] (notification) in
                                                    withExtendedLifetime(self, {
                                                        self!.handleDidHideNotification(notification: notification)
                                                    })
        }
        observers.append(observer)
        
        observer = notificationCenter.addObserver(forName: .UIKeyboardWillShow,
                                                  object: nil,
                                                  queue: queue) { [weak self] (notification) in
                                                    withExtendedLifetime(self, {
                                                        self!.handleWillShowNotification(notification: notification)
                                                    })
        }
        observers.append(observer)
        
        observer = notificationCenter.addObserver(forName: .UIKeyboardDidShow,
                                                  object: nil,
                                                  queue: queue) { [weak self] (notification) in
                                                    withExtendedLifetime(self, {
                                                        self!.handleDidShowNotification(notification: notification)
                                                    })
        }
        observers.append(observer)
    }
    
    // MARK: - Handling Notificaitons
    
    func handleWillHideNotification(notification: Notification) {
        sendEvent(type: .willHide, userInfo: notification.userInfo! as NSDictionary)
    }
    
    func handleDidHideNotification(notification: Notification) {
        sendEvent(type: .didHide, userInfo: notification.userInfo! as NSDictionary)
    }
    
    func handleWillShowNotification(notification: Notification) {
        sendEvent(type: .willShow, userInfo: notification.userInfo! as NSDictionary)
    }
    
    func handleDidShowNotification(notification: Notification) {
        sendEvent(type: .didShow, userInfo: notification.userInfo! as NSDictionary)
    }
}
