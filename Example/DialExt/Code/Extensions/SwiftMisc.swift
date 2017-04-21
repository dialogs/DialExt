//
//  SwiftMisc.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 19/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

// Extending Misc.swift from Swift library

/// Performs block only if instance is not nil.
public func withOptionalExtendedLifetime<T, Result>(_ x: T?,
                                     _ ifNilResult: Result? = nil,
                                     _ body:() throws -> Result) rethrows -> Result? {
    return try withExtendedLifetime(x, {
        guard x != nil else {
            return ifNilResult
        }
        return try body()
    })
}

public func withOptionalExtendedLifetime<T>(_ x: T?, body: (() -> ()) ) {
    withExtendedLifetime(x) {
        guard x != nil else {
            return
        }
        return body()
    }
}

/// Performs block only if instance is not nil. Does not pass instance into performing block.
public func withOptionalExtendedLifetime<T, Result>(_ x: T?,
                                     _ ifNilResult: Result? = nil,
                                     _ body: (T) throws -> Result) rethrows -> Result? {
    return try withExtendedLifetime(x, {
        guard let notNilX = x else {
            return ifNilResult
        }
        return try body(notNilX)
    })
}
