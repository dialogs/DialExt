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
        
        public var idString: String {
            return String(describing: self.id)
        }
        
        public let peerType: PeerType
        
        public let accessHash: Int64
        
        public var accessHashString: String {
            return String(describing: self.accessHash)
        }
        
        public init(id: Int64, peerType: PeerType, accessHash: Int64) {
            self.id = id
            self.peerType = peerType
            self.accessHash = accessHash
        }
        
        public init(dialog: AppSharedDialog) {
            self.init(id: dialog.id, peerType : dialog.isGroup ? .group : .private, accessHash: dialog.accessHash)
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