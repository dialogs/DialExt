import Foundation


public struct DEUploadAuth {
    
    let authId: DEAuthId
    
    let signedAuthId: Data
    
    public var httpQueryValue: String {
        return "\(self.authId)|\(signedAuthId.hexString)"
    }
    
    public init(authId: DEAuthId, signedAuthId: Data) {
        self.authId = authId
        self.signedAuthId = signedAuthId
    }
}
