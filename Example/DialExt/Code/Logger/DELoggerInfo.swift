//
//  DELoggerInfo.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 23/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public struct DELoggerInfoKey: RawRepresentable, Hashable {
    
    public typealias RawValue = String
    
    public let rawValue: RawValue
    
    init(_ rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    public var hashValue: Int {
        return self.rawValue.hashValue
    }
    
    public static func ==(lhs: DELoggerInfoKey, rhs: DELoggerInfoKey) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    
    public static let exception = DELoggerInfoKey.init("im.dlg.logger.key.exception")
    
    public static let error = DELoggerInfoKey.init("im.dlg.logger.key.error")
    
    public static let afterward = DELoggerInfoKey.init("im.dlg.logger.key.afterward")
}


public typealias DELoggerInfo = [DELoggerInfoKey : Any]

public extension DELogger {
    public typealias Info = DELoggerInfo
}
