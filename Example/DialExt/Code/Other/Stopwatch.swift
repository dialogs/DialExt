//
//  Stopwatch.swift
//  Alamofire
//
//  Created by Aleksei Gordeev on 07/11/2017.
//

import Foundation


public class Stopwatch {
    
    public var onFire:((_ left: TimeInterval) -> ())? = nil
    
    public var started: Bool {
        return self.timer != nil
    }
    
    private var timer: Timer? = nil
    
    private var timeout: TimeInterval = 0.0
    
    public init() {
        // do nothing
    }
    
    public func start(timeout: TimeInterval) {
        if self.started {
            self.stop()
        }
        
        self.timeout = timeout
        let timer = Timer.scheduledTimer(timeInterval: 1.0,
                                         target: self,
                                         selector: #selector(handleTimerFire(_:)),
                                         userInfo: nil,
                                         repeats: true)
        self.timer = timer
    }
    
    @objc private func handleTimerFire(_ timer: Timer) {
        guard timer == self.timer else {
            return
        }
        
        guard self.timeout > 0.0 else {
            return
        }
        
        self.timeout -= 1.0
        self.onFire?(self.timeout)
        
        if self.timeout <= 0.0 {
            self.stop()
        }
    }
    
    public func stop() {
        if let timer = self.timer {
            timer.invalidate()
        }
        self.timer = nil
    }
    
}
