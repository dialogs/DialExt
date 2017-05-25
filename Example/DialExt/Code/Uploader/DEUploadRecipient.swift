import Foundation

public struct DEUploadRecipient: CustomStringConvertible {
    
    public let id: Int32
    
    public var idString: String {
        return String(describing: self.id)
    }
    
    public let peerType: PeerType
    
    public let accessHash: Int64
    
    public var accessHashString: String {
        return String(describing: self.accessHash)
    }
    
    public init(id: Int32, peerType: PeerType, accessHash: Int64) {
        self.id = id
        self.peerType = peerType
        self.accessHash = accessHash
    }
    
    public init(dialog: AppSharedDialog) {
        self.init(id: dialog.peerId, peerType : dialog.isGroup ? .group : .private, accessHash: dialog.accessHash)
    }
    
    public enum PeerType: CustomStringConvertible {
        case group, `private`
        
        var string: String {
            switch self {
            case .group: return "group"
            case .private: return "private"
            }
        }
        
        public var description: String {
            return string
        }
    }
    
    var multipartFormPeerKey: String {
        let key: String
        switch self.peerType {
        case .group:
            key = "GROUP_\(self.id)"
        case .private:
            key = "PRIVATE_\(self.id)"
        }
        return key
    }
    
    var mulitpartFormPeerDescription: String {
        return "\(self.multipartFormPeerKey):\(self.accessHashString)"
    }
    
    public var description: String {
        return multipartFormPeerKey
    }
}
