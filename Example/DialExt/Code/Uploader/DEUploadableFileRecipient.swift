//
//  DEUploadableFileRecipient.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 14/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension DEFileUploader {
    
    public struct Recipient {
        
        public let id: Int64
        
        public let peerType: PeerType
        
        public init(id: Int64, peerType: PeerType) {
            self.id = id
            self.peerType = peerType
        }
        
        public enum PeerType {
            case group, `private`
            
            var string: String {
                switch self {
                case .group: return "group"
                case .private: return "private"
                }
            }
        }
        
    }
    
}
