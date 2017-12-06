//
//  ThreadSafeBox.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 06/12/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public class ThreadSafeBox<V> {
    
    private let mutex: PThreadMutex
    
    public var value: V? {
        
        set {
            perform {
                self.unsafeValue = value
            }
        }
        
        get {
            var value: V? = nil
            perform {
                value = unsafeValue
            }
            return value
        }
    }
    
    private var unsafeValue: V? = nil
    
    public init(mutex : PThreadMutex, value: V? = nil) {
        self.mutex = mutex
        self.unsafeValue = value
    }
    
    private func perform(_ block:(()->())) {
        mutex.sync(execute:{
            block()
        })
    }
    
}
