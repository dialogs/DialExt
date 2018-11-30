//
//  CertificateKeeper.swift
//  DialExt
//
//  Created by Lex on 30/11/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation


public protocol DECertificateKeeperReadable {
    
    /// - returns: A certificate if there was one previously stored in secure storage.
    func readCertificate() throws -> SecIdentity?
}

public protocol DECertificateKeeperWriteable {
    
    /// Writes or overwrites a certificate into a secure storage.
    func writeCertificate(_ cert: SecIdentity) throws
    
    /// Deletes a certificate or does nothing if there was no certificate found in secure storage.
    func deleteCertificate() throws
}


public final class DECertificateKeeper: DECertificateKeeperReadable, DECertificateKeeperWriteable {
    
    
    // MARK: - Vars
    
    public static let defaultKey: String = "im.dlg.certificate"
    
    public let key: String
    
    public let group: String?
    
    // MARK: - Init
    
    public init(key: String = DECertificateKeeper.defaultKey, group: String?) {
        self.key = key
        self.group = group
    }
    
    // MARK: - Read & Write Protocols
    
    public func readCertificate() throws -> SecIdentity? {
        let query = createQuery(.read)
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess, let item = item, let cert: SecIdentity = compileSafeCast(instance: item) {
            return cert
        }
        
        if status == errSecItemNotFound {
            return nil
        }
        
        throw createError(status: status)
    }
    
    public func writeCertificate(_ cert: SecIdentity) throws {
        try self.deleteCertificate()
        
        let query = self.createQuery(.write(identity: cert))
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw createError(status: status)
        }
    }
    
    public func deleteCertificate() throws {
        let query = self.createQuery(.delete)
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess, errSecItemNotFound:
            break
        default: 
            throw createError(status: status)
        }
    }
    
    // MARK: - Private Funcs
    
    private func createError(status: OSStatus) -> NSError {
        return NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
    }
    
    private func createQuery(_ type: QueryType) -> [String: Any] {
        
        switch type {
        case .delete:
            return [kSecClass as String: kSecClassIdentity]
            
        case .read:
            var query: [String: Any] = [kSecClass as String: kSecClassIdentity,
                                        kSecAttrLabel as String: key,
                                        kSecReturnRef as String: kCFBooleanTrue]
            appendQueryByGroupIfNeeded(&query)
            return query
            
        case .write(let cert):
            var query: [String: Any] = [
                kSecValueRef as String: cert,
                kSecAttrLabel as String: key,
                kSecReturnRef as String: kCFBooleanTrue]
            appendQueryByGroupIfNeeded(&query)
            return query
        }
        
    }
    
    private func appendQueryByGroupIfNeeded(_ query: inout [String : Any]) {
        if let group = group {
            query[kSecAttrAccessGroup as String] = group as String
        }
    }
    
    /// Workaround for compiler error (neither "as?" neither "as" not acceptable)
    /// But forced unwrap is not acceptable by team convention.
    private func compileSafeCast<NewType>(instance: AnyObject) -> NewType? {
        return instance as? NewType
    }
    
    private enum QueryType {
        case write(identity: SecIdentity)
        case read
        case delete
    }
}
