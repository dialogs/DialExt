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
            
            let boundary = self.boundary
            
            let url = components.url!
            let request = NSMutableURLRequest.init(url: url)
            request.setValue("multipart/form-data; boundary=\(boundary.string)", forHTTPHeaderField: "Content-Type")
            
            request.httpMethod = "PUT"
            
            let recipients = [info.recipient]
            let body = buildBody(recipients: recipients, boundary: boundary, file: info.file)
            request.httpBody = body
            
            return request.copy() as! URLRequest
        }
        
        private func buildQueryItems(info: UploadInfo) -> [URLQueryItem] {
            let authItem = URLQueryItem.init(preservedName: .signedAuthId, value: info.authInfo.httpQueryValue)
            let peerItem = URLQueryItem.init(preservedName: .peerId, value: info.recipient.idString)
            let peerTypeItem = URLQueryItem.init(preservedName: .peerType, value: info.recipient.peerType.string)
            let accessHashItem = URLQueryItem.init(preservedName: .accessHash, value: info.recipient.accessHashString)
            
            return [authItem, peerItem, peerTypeItem, accessHashItem]
        }
        
        private func buildBody(parameters: [String: String] = [:], recipients: [Recipient], boundary: Boundary, file: File) -> Data {
            return buildBody(parameters: [:], recipients: recipients, data: file.data, mimeType: file.mimetype, filename: file.name)
        }
        
        private func buildBody(parameters: [String: String],
                               recipients: [Recipient],
                               boundary: Boundary = Boundary.init(),
                               data: Data,
                               mimeType: String,
                               filename: String) -> Data {
            
            let body = NSMutableData.init()
            
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
                appendBody(contentDispositionSuffix: "name=\"\(key)\"".appending(byNewLines: 2))
                appendBody(string: value.appending(byNewLines: 1))
            }
            
            appendBody(string: boundary.prefixedString.appending(byNewLines: 1))
            for recipient in recipients {
                appendBody(string: boundary.prefixedString.appending(byNewLines: 1))
                let peerDescription = recipient.mulitpartFormPeerDescription
                appendBody(contentDispositionSuffix: "name=\"peer\"; \(peerDescription);".appending(byNewLines: 2))
            }
            appendBody(string: boundary.prefixedString.appending(byNewLines: 1))
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
            let authInfo: AuthInfo
            
            public init(url: URL,
                        file: File,
                        recipient: Recipient,
                        authInfo: AuthInfo) {
                self.url = url
                self.file = file
                self.recipient = recipient
                self.authInfo = authInfo
            }
            
        }
        
        public struct AuthInfo {
            
            let authId: DEAuthId
            
            let signedAuthId: Data
            
            public var httpQueryValue: String {
                return "\(self.authId)|\(signedAuthId.hexString)"
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
