//
//  DEFileUploader+RequestBuilder.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 14/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation


public extension DEFileUploader {
    
    public class RequestBuilder {
        
        public var boundaryString: String?
        
        private var boundary: Boundary {
            if let boundaryString = self.boundaryString {
                return Boundary.init(string: boundaryString)
            }
            return Boundary.init()
        }
        
        public init() {
            // do nothing
        }
        
        public func buildRequest(info: UploadInfo) -> URLRequest {
            
            var components = URLComponents(url: info.url, resolvingAgainstBaseURL: false)!
            components.queryItems = buildQueryItems(info: info)
            
            let boundary = "Boundary-\(UUID.init().uuidString)"
            
            let url = components.url!
            let request = NSMutableURLRequest.init(url: url)
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            request.httpMethod = "POST"
            
            let body = buildBody(parameters: [:], boundary: self.boundary, file: info.file)
            request.httpBody = body
            
            return request.copy() as! URLRequest
        }
        
        private func buildQueryItems(info: UploadInfo) -> [URLQueryItem] {
            let value = info.authInfo.httpQueryValue
            let authItem = URLQueryItem.init(preservedName: .signedAuthId, value: value)
            
            let peerItem = URLQueryItem.init(preservedName: .peerId, value: String(describing: info.recipient.id))
            let peerTypeItem = URLQueryItem.init(preservedName: .peerType, value: info.recipient.peerType.string)
            
            let accessHashItem = URLQueryItem.init(preservedName: .accessHash, value: info.sender.accessHashString!)
            
            return [authItem, peerItem, peerTypeItem, accessHashItem]
        }
        
        private func buildBody(parameters: [String: String],
                               boundary: Boundary = Boundary.init(),
                               file: File) -> Data {
            return buildBody(parameters: [:], data: file.data, mimeType: file.mimetype, filename: file.name)
        }
        
        private func buildBody(parameters: [String: String],
                               boundary: Boundary = Boundary.init(),
                               data: Data,
                               mimeType: String,
                               filename: String) -> Data {
            
            let body = NSMutableData.init()
            
            let boundaryPrefix = "--\(boundary)\r\n"
            
            func appendBody(string: String) {
                let data = string.data(using: .utf8, allowLossyConversion: false)!
                body.append(data)
            }
            
            func appendBody(contentDispositionSuffix suffix: String) {
                let string = "Content-Disposition: form-data; \(suffix)"
                appendBody(string: string)
            }
            
            for (key, value) in parameters {
                appendBody(string: boundary.prefixedString.appending(byNewLines: 1))
                appendBody(string: boundary.prefixedString)
                appendBody(contentDispositionSuffix: "name=\"\(key)\"".appending(byNewLines: 2))
                appendBody(string: value.appending(byNewLines: 1))
            }
            
            appendBody(string: boundary.prefixedString)
            appendBody(contentDispositionSuffix: "name=\"file\"; filename=\"\(filename)\"".appending(byNewLines: 1))
            appendBody(string: "Content-Type: \(mimeType)".appending(byNewLines: 2))
            
            body.append(data)
            
            appendBody(string: "".appending(byNewLines: 1))
            appendBody(string: boundary.wrappedString)
            
            return body as Data
        }
        
        
        public struct UploadInfo {
            let url: URL
            let file: File
            let recipient: Recipient
            let sender: Sender
            let authInfo: AuthInfo
            
            public init(url: URL,
                        file: File,
                        sender: Sender,
                        recipient: Recipient,
                        authInfo: AuthInfo) {
                self.url = url
                self.file = file
                self.sender = sender
                self.recipient = recipient
                self.authInfo = authInfo
            }
            
        }
        
        public struct Sender {
            
            public let accessHash: Data
            
            var accessHashString: String? {
                return String(data: self.accessHash, encoding: .utf8)
            }
            
            public init(accessHash: Data) {
                self.accessHash = accessHash
            }
            
        }
        
        public struct AuthInfo {
            
            let authId: DEAuthId
            
            let signedAuthId: Data
            
            public var httpQueryValue: String {
                let signedAuthIdString = String.init(data: self.signedAuthId, encoding: .utf8)
                return "\(self.authId)|\(signedAuthIdString)"
            }
            
            internal init(authId: DEAuthId, signedAuthId: Data) {
                self.authId = authId
                self.signedAuthId = signedAuthId
            }
        }
        
        private struct Boundary {
            
            let string: String
            
            var prefixedString: String {
                return "--\(string)"
            }
            
            var wrappedString: String {
                return prefixedString.appending("--")
            }
            
            init(string: String = "Boundary-\(UUID.init().uuidString)") {
                self.string = string
            }
        }
        
    }
    
}
