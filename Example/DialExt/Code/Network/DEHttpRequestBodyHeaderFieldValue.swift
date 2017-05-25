//
//  DEHttpRequestBodyHeaderFieldValue.swift
//  Pods
//
//  Created by Aleksei Gordeev on 24/05/2017.
//
//

import Foundation

public extension DEHttpRequestBody {
    
    public struct HeaderFieldValue: RawRepresentable, Equatable, Hashable, Comparable {
        
        public private(set) var rawValue: String
        
        public init(_ rawValue: String) {
            self.init(rawValue: rawValue)
        }
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public static func ==(lhs: HeaderFieldValue, rhs: HeaderFieldValue) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
        
        /// :nodoc:
        public static func <(lhs: HeaderFieldValue, rhs: HeaderFieldValue) -> Bool {
            return rhs.rawValue < rhs.rawValue
        }
        
        public var hashValue: Int {
            return self.rawValue.hashValue
        }
        
    }
    
}

public extension DEHttpRequestBody.HeaderFieldValue {
    
    public static let formData = DEHttpRequestBody.HeaderFieldValue.init("form-data")
    
}
