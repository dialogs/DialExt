//
//  DEHttpRequestBodyHeaderFieldName.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 24/05/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//


import Foundation

public extension DEHttpRequestBody {
    
    public struct HeaderFieldName : RawRepresentable, Equatable, Hashable, Comparable {
        
        public private(set) var rawValue: String
        
        public init(_ rawValue: String) {
            self.init(rawValue: rawValue)
        }
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        /// :nodoc:
        public static func ==(lhs: HeaderFieldName, rhs: HeaderFieldName) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
        
        /// :nodoc:
        public static func <(lhs: HeaderFieldName, rhs: HeaderFieldName) -> Bool {
            return rhs.rawValue < rhs.rawValue
        }
        
        /// :nodoc:
        public var hashValue: Int {
            return self.rawValue.hashValue
        }
        
    }
    
}

public extension DEHttpRequestBody.HeaderFieldName {
    
    /// Content-Disposition
    public static let contentDisposition = DEHttpRequestBody.HeaderFieldName.init("Content-Disposition")
    
    /// Content-Type
    public static let contentType = DEHttpRequestBody.HeaderFieldName.init("Content-Type")
}
