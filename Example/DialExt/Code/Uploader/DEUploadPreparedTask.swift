import Foundation

public class DEUploadPreparedTask: Equatable {
    
    public let recipients: [DEUploadRecipient]
    
    public let items: [DEUploadPreparedItem]
    
    public let auth: DEQueryAuth
    
    public let uuid: UUID
    
    public let boundary: String
    
    public var proposedMessage: String? {
        for item in items {
            if let message = item.messageRepresentable {
                return message
            }
        }
        return nil
    }
    
    public init(recipients: [DEUploadRecipient],
                items: [DEUploadPreparedItem],
                auth: DEQueryAuth,
                uuid: UUID = UUID(),
                boundary: String? = nil) {
        
        self.recipients = recipients
        self.items = items
        self.auth = auth
        
        self.uuid = uuid
        self.boundary = boundary ?? uuid.uuidString
    }
    
    public static func ==(lhs: DEUploadPreparedTask, rhs: DEUploadPreparedTask) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
}
