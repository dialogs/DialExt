import Foundation

public protocol DEQueryAuth {
    func makeQueryItem() -> URLQueryItem
    func write(writer: DEKeychainQueryPerformerable) throws
}

public enum DEUploadAuthPolicy {
    case `default`
    case token
}

public class DEUploadAuth : DEQueryAuth {

    let authId: DEAuthId
    
    let signedAuthId: Data
    
    public init(authId: DEAuthId, signedAuthId: Data) {
        self.authId = authId
        self.signedAuthId = signedAuthId
    }
    
    public func makeQueryItem() -> URLQueryItem {        
        return URLQueryItem.init(preservedName: .signedAuthId, value: "\(self.authId)|\(signedAuthId.de_hexString)")
    }
    
    public func write(writer: DEKeychainQueryPerformerable) throws {
        let idData = authId.authIdToData() as NSData
        try writer.rewrite(addQuery: .writeShared(.authIdService, data: idData))
        
        let signedData = signedAuthId as NSData
        try writer.rewrite(addQuery: .writeShared(.signedIdAuthIdService, data: signedData))
    }
}

public class DEUploadTokenAuth : DEQueryAuth {
    
    let token: String
    
    public init(token: String) {
        self.token = token
    }
    
    public func makeQueryItem() -> URLQueryItem {
        return URLQueryItem.init(preservedName: .token, value: token)
    }
    
    public func write(writer: DEKeychainQueryPerformerable) throws {
        let data = token.data(using: .utf8)
        try writer.rewrite(addQuery: .writeShared(.tokenService, data: data! as NSData))
    }
}
