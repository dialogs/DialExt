//  Copyright © 2016 Aleksei Gordeev. All rights reserved.

import Foundation

extension Notification.Name {
    static let KeyboardListenerDidDetectEvent = Notification.Name("KeyboardListenerDidDetectEvent")
}

open class KeyboardListener: KeyboardDetectorDelegate {
    
    public static let shared = KeyboardListener.init()
    
    static let eventUserInfoKey = "com.vladlex.keyboardListener.userInfo.event"
    
    public enum KeyboardState {
        case presented
        case beingPresented
        case dismissed
        case beingDismissed
    }
    
    /**
     * State defined by keyboard detector
     */
    public var declaredState: KeyboardState? {
        guard let event = lastEvent else {
            return nil
        }
        
        let state: KeyboardState
        switch event.type {
        case .willShow:
            state = .beingPresented
        case .didShow:
            state = .presented
        case .willHide:
            state = .beingDismissed
        case .didHide:
            state = .dismissed
        }
        return state
    }
    
    /**
     * Returns state using proposition that if declared state is nil, then keyboard is dismissed.
     */
    public var proposedState: KeyboardState {
        return declaredState ?? .dismissed
    }
    
    private(set) var lastEvent: KeyboardEvent?
    
    private let detector: KeyboardDetector
    
    init(detector: KeyboardDetector = NotificationBasedKeyboardDetector.init()) {
        self.detector = detector
        self.detector.delegate = self
    }
    
    func keyboardDetector(_ keyboardDetector: KeyboardDetector, detectEvent event: KeyboardEvent) {
        lastEvent = event
        post(event: event)
    }
    
    private func post(event: KeyboardEvent) {
        let notification = Notification.init(name: .KeyboardListenerDidDetectEvent,
                                             object: self,
                                             userInfo: [KeyboardListener.eventUserInfoKey: event])
        NotificationCenter.default.post(notification)
    }
}


