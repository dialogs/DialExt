//
//  DEUploadRequestBuilder.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 23/05/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public protocol DEUploadRequestBuilderable {
    func buildRequest(task: DEUploadPreparedTask) throws -> URLRequest
    
    func resetApiUrl(_ url: URL)
    
}

public class DEUploadRequestBuilder: DEUploadRequestBuilderable {
    
    public private(set) var apiUrl: URL
    
    public init(apiUrl: URL) {
        self.apiUrl = apiUrl
    }
    
    public func resetApiUrl(_ url: URL) {
        self.apiUrl = url
    }
    
    public func buildRequest(task: DEUploadPreparedTask) throws -> URLRequest {
    
        var components = URLComponents(url: self.apiUrl, resolvingAgainstBaseURL: false)!
        
        var queryItems: [URLQueryItem] = components.queryItems ?? []
        queryItems.append(contentsOf: self.buildQueryItems(task: task))
        components.queryItems = queryItems
        components.percentEncodedQuery = components.percentEncodedQuery?
            .replacingOccurrences(of: "+", with: "%2B")
        
        let request = NSMutableURLRequest.init(url: components.url!)
        request.setValue("multipart/form-data; boundary=\(task.boundary)", forHTTPHeaderField: "Content-Type")
        
        let body = buildBody(task: task)
        request.httpBody = body
        request.setValue(String(describing: body.count), forHTTPHeaderField: "Content-Length")
        if let digest = buildDigest(task: task) {
            request.setValue(digest, forHTTPHeaderField: "digest")
        }
        
        request.httpMethod = "POST"
        
        return request.copy() as! URLRequest
    }
    
    private func buildDigest(task: DEUploadPreparedTask) -> String? {
        for item in task.items {
            switch item.content {
            case let .image(rep): return rep.dataRepresentation.data.digestSHA1.de_hexString
            case let .video(rep): return rep.dataRepresentation.data.digestSHA1.de_hexString
            case let .audio(rep): return rep.dataRepresentation.data.digestSHA1.de_hexString
            case let .bytes(rep): return rep.data.digestSHA1.de_hexString
            default: break
            }
        }
        return nil
    }
    
    private func buildBody(task: DEUploadPreparedTask) -> Data {
        
        var body = DEHttpRequestBody.init()
        
        body.append(byLineBreaks: 1)
        
        // MARK: Fill Recipients
        task.recipients.forEach {
            body.appendBody(byRecipient: $0, boundary: task.boundary)
        }
        
        // MARK: Fill Data-content
        task.items.enumerated().forEach { (idx, item) in
            body.append(byItem: item, idx: idx, boundary: task.boundary)
        }
        
        // MARK: Fill Message
        if let message = task.proposedMessage {
            body.append(byMessage: message, boundary: task.boundary)
        }
        
        body.append(byBoundary: task.boundary, suffixed: true)
        
        return body.data
    }
    
    private func buildQueryItems(task: DEUploadPreparedTask) -> [URLQueryItem] {
        let authItem = task.auth.makeQueryItem()
        return [authItem]
    }
}

fileprivate extension DEHttpRequestBody.HeaderFieldAttribute {
    
    fileprivate static func dispositionName(_ name: String) -> DEHttpRequestBody.HeaderFieldAttribute {
        return DEHttpRequestBody.HeaderFieldAttribute.init(key: "name", value: name)
    }
    
    fileprivate static func dispositionFileName(_ filename: String) -> DEHttpRequestBody.HeaderFieldAttribute {
        return DEHttpRequestBody.HeaderFieldAttribute.init(key: "filename", value: filename)
    }
    
    fileprivate static func dispositionDuration(_ duration: Int) -> DEHttpRequestBody.HeaderFieldAttribute {
        return DEHttpRequestBody.HeaderFieldAttribute.init(key: "duration", value: "\(duration)".wrappingByQuotes())
    }
    
    fileprivate static func dispositionWidth(_ width: Int) -> DEHttpRequestBody.HeaderFieldAttribute {
        return DEHttpRequestBody.HeaderFieldAttribute.init(key: "width", value: "\(width)".wrappingByQuotes())
    }
    
    fileprivate static func dispositionHeight(_ height: Int) -> DEHttpRequestBody.HeaderFieldAttribute {
        return DEHttpRequestBody.HeaderFieldAttribute.init(key: "height", value: "\(height)".wrappingByQuotes())
    }
    
}


fileprivate extension DEHttpRequestBody {
    
    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter.init()
        
        return formatter
    }()
    
    mutating fileprivate func append(byMessage: String, boundary: String) {
        self.append(byBoundary: boundary)
        self.append(byHeaderField: .createMultipartFormDispositionItem(named: "notice"))
        self.append(byHeaderField: .init(name: .contentType, value: .init("text/plain"), attrs: ["charset": "UTF-8"]))
        self.append(byLineBreaks: 1)
        self.append(byString: byMessage)
    }
    
    mutating fileprivate func append(byDisposition disposition: HeaderFieldEntry,
                                     contentType: HeaderFieldEntry,
                                     data: Data,
                                     boundary: String) {
        self.append(byBoundary: boundary)
        self.append(by: disposition, String.httpRequestBodyLineBreak,
                    contentType, String.httpRequestBodyLineBreak,
                    String.httpRequestBodyLineBreak,
                    data, String.httpRequestBodyLineBreak)
    }
    
    mutating fileprivate func append(byItem item: DEUploadPreparedItem, idx: Int, boundary: String) {
        
        let name = "file_\(String(describing: idx))"
        
        var disposition: HeaderFieldEntry! = nil
        var contentType: HeaderFieldEntry! = nil
        var data: Data! = nil
        
        
        let fileName = item.proposeName(baseBuilder: {
            let date = DEHttpRequestBody.fileDateFormatter.string(from: Date())
            let filenameBase = "\(idx)_\(arc4random())_\(date)"
            return filenameBase
        })
        
        switch item.content {
        case let .audio(audio):
            let attributes: [DEHttpRequestBody.HeaderFieldAttribute] = [
                DEHttpRequestBody.HeaderFieldAttribute.dispositionName(name.wrappingByQuotes()),
                DEHttpRequestBody.HeaderFieldAttribute.dispositionFileName(fileName.wrappingByQuotes()),
                DEHttpRequestBody.HeaderFieldAttribute.dispositionDuration(audio.details.durationInSeconds)
            ]
            disposition = HeaderFieldEntry.init(name: .contentDisposition, value: .formData, attributes: attributes)
            contentType = HeaderFieldEntry.init(name: .contentType,
                                                value: .init(audio.dataRepresentation.mimeType))
            data = audio.dataRepresentation.data
            
        case let .video(video):
            let attributes: [DEHttpRequestBody.HeaderFieldAttribute] = [
                DEHttpRequestBody.HeaderFieldAttribute.dispositionName(name.wrappingByQuotes()),
                DEHttpRequestBody.HeaderFieldAttribute.dispositionFileName(fileName.wrappingByQuotes()),
                DEHttpRequestBody.HeaderFieldAttribute.dispositionWidth(video.details.size.width),
                DEHttpRequestBody.HeaderFieldAttribute.dispositionHeight(video.details.size.height),
                DEHttpRequestBody.HeaderFieldAttribute.dispositionDuration(video.details.durationInSeconds)
            ]
            disposition = HeaderFieldEntry.init(name: .contentDisposition, value: .formData, attributes: attributes)
            contentType = HeaderFieldEntry.init(name: .contentType,
                                                value: .init(video.dataRepresentation.mimeType))
            data = video.dataRepresentation.data
            
        case let .image(image):
            let attributes: [DEHttpRequestBody.HeaderFieldAttribute] = [
                DEHttpRequestBody.HeaderFieldAttribute.dispositionName(name.wrappingByQuotes()),
                DEHttpRequestBody.HeaderFieldAttribute.dispositionFileName(fileName.wrappingByQuotes()),
                DEHttpRequestBody.HeaderFieldAttribute.dispositionWidth(image.details.size.width),
                DEHttpRequestBody.HeaderFieldAttribute.dispositionHeight(image.details.size.height),
                ]
            disposition = HeaderFieldEntry.init(name: .contentDisposition, value: .formData, attributes: attributes)
            contentType = HeaderFieldEntry.init(name: .contentType,
                                                value: .init(image.dataRepresentation.mimeType))
            data = image.dataRepresentation.data
            
        case let .bytes(bytes):
            let attributes: [DEHttpRequestBody.HeaderFieldAttribute] = [
                DEHttpRequestBody.HeaderFieldAttribute.dispositionName(name.wrappingByQuotes()),
                DEHttpRequestBody.HeaderFieldAttribute.dispositionFileName(fileName.wrappingByQuotes())
            ]
            disposition = HeaderFieldEntry.init(name: .contentDisposition, value: .formData, attributes: attributes)
            contentType = HeaderFieldEntry.init(name: .contentType,
                                                value: .init(bytes.mimeType))
            data = bytes.data
            
        default: return
        }
        
        self.append(byDisposition: disposition, contentType: contentType, data: data, boundary: boundary)
        
        if let preview = item.preview {
            
            let name = "preview_\(String(describing:idx))"
            let fileName = preview.filename(base: name)
            
            let disposition = HeaderFieldEntry.init(name: .contentDisposition, value: .formData, attributes: [
                DEHttpRequestBody.HeaderFieldAttribute.dispositionName(name.wrappingByQuotes()),
                DEHttpRequestBody.HeaderFieldAttribute.dispositionFileName(fileName.wrappingByQuotes()),
                DEHttpRequestBody.HeaderFieldAttribute.dispositionWidth(preview.details.size.width),
                DEHttpRequestBody.HeaderFieldAttribute.dispositionHeight(preview.details.size.height),
                ])
            let contentType = HeaderFieldEntry.init(name: .contentType,
                                                    value: .init(preview.dataRepresentation.mimeType))
            let data = preview.dataRepresentation.data
            
            self.append(byDisposition: disposition, contentType: contentType, data: data, boundary: boundary)
        }
    }
    
    mutating fileprivate func appendBody(byRecipient recipient: DEUploadRecipient, boundary: String) {
        self.append(byBoundary: boundary)
        
        self.append(byHeaderField: .createMultipartFormDispositionItem(named: "peer"))
        self.append(byHeaderField: .init(name: .contentType,
                                         value: .init("text/plain"),
                                         attrs: ["charset" : "UTF-8"]))
        self.append(byLineBreaks: 1)
        self.append(byString: recipient.mulitpartFormPeerDescription)
    }
}
