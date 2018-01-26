//
//  URLQueryItem+PreservedName.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 17/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension URLQueryItem {
    
    
    init(preservedName: PreservedName, value: String) {
        self.init(name: preservedName.rawValue, value: value)
    }
    
    
    public struct PreservedName : RawRepresentable, Equatable, Hashable, Comparable {
        
        // MARK: - Content
        
        public private(set) var rawValue: String
        
        public init(_ rawValue: String) {
            self.init(rawValue: rawValue)
        }
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public var hashValue: Int {
            return self.rawValue.hash
        }
        
        public static func ==(lhs: URLQueryItem.PreservedName, rhs: URLQueryItem.PreservedName) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
        
        public static func <(lhs: URLQueryItem.PreservedName, rhs: URLQueryItem.PreservedName) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
        
        // MARK: - Constants
        
        public static let signedAuthId = PreservedName.init(rawValue: "signedAuthId")
        
        public static let token = PreservedName.init(rawValue: "token")
        
        public static let peerType = PreservedName.init(rawValue: "peer_type")
        
        public static let peerId = PreservedName.init(rawValue: "peer_id")
        
        public static let accessHash = PreservedName.init(rawValue: "access_hash")
        
    }

    
}
