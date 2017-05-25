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
}

public class DEUploadRequestBuilder: DEUploadRequestBuilderable {
    
    public let apiUrl: URL
    
    public init(apiUrl: URL) {
        self.apiUrl = apiUrl
    }
    
    public func buildRequest(task: DEUploadPreparedTask) throws -> URLRequest {
        
        var components = URLComponents(url: self.apiUrl, resolvingAgainstBaseURL: false)!
        
        var queryItems: [URLQueryItem] = components.queryItems ?? []
        queryItems.append(contentsOf: self.buildQueryItems(task: task))
        components.queryItems = queryItems
        
        let request = NSMutableURLRequest.init(url: components.url!)
        request.setValue("multipart/form-data; boundary=\(task.boundary)", forHTTPHeaderField: "Content-Type")
        
        let body = buildBody(task: task)
        request.httpBody = body
        request.setValue(String(describing: body.count), forHTTPHeaderField: "Content-Length")
        
        request.httpMethod = "POST"
        
        return request.copy() as! URLRequest
    }
    
    private func buildBody(task: DEUploadPreparedTask) -> Data {
        
        var body = DEHttpRequestBody.init()
        
        body.append(byLineBreaks: 1)
        
        // MARK: Fill Recipients
        task.recipients.forEach {
            body.appendBody(byRecipient: $0, boundary: task.boundary)
        }
        
        // MARK: Fill Data-content
        task.mediaFiles.enumerated().forEach { (idx, file) in
            body.append(byFile: file, idx: idx, boundary: task.boundary)
        }
        
        // MARK: Fill Message
        if let message = task.proposedMessage {
            body.append(byMessage: message, boundary: task.boundary)
        }
        
        body.append(byBoundary: task.boundary, suffixed: true)
        
        return body.data
    }
    
    private func buildQueryItems(task: DEUploadPreparedTask) -> [URLQueryItem] {
        let authItem = URLQueryItem.init(preservedName: .signedAuthId, value: task.auth.httpQueryValue)
        return [authItem]
    }
}


fileprivate extension DEHttpRequestBody {
    
    mutating fileprivate func append(byMessage: String, boundary: String) {
        self.append(byBoundary: boundary)
        self.append(byHeaderField: .createMultipartFormDispositionItem(named: "Notice"))
        self.append(byHeaderField: .init(name: .contentType, value: .init("text.plain"), attrs: ["charset": "UTF-8"]))
        self.append(byString: byMessage)
    }
    
    mutating fileprivate func append(byFile: DEUploadPreparedItem.MediaFile, idx: Int, boundary: String) {
        self.append(byBoundary: boundary)
        
        let name = "file_\(String(describing: idx))"
        var fileName = "file_\(String(describing: idx))"
        if let ext = byFile.file.fileExtension {
            fileName.append(".\(ext)")
        }
        let fileRep = File.init(name: name,
                                filename: fileName,
                                mimeType: byFile.file.mimeType,
                                data: byFile.file.data)
        self.append(byItems: fileRep.bodyItems)
        
        if let preview = byFile.preview {
            self.append(byBoundary: boundary)
            
            let size = preview.size!
            let previewName = "\"preview_\(String(describing:idx))\""
            let previewHeaderField = HeaderFieldEntry.init(name: .contentDisposition,
                                                           value: .formData,
                                                           attrs: ["name" : previewName,
                                                                   "width" : String(describing:size.width),
                                                                   "height" : String(describing: size.height)])
            let previewContentTypeField = HeaderFieldEntry.init(name: .contentType, value: .init(preview.mimeType))
            self.append(by: previewHeaderField, String.httpRequestBodyLineBreak,
                        previewContentTypeField, String.httpRequestBodyLineBreak,
                        String.httpRequestBodyLineBreak,
                        preview.data)
        }
    }
    
    mutating fileprivate func appendBody(byRecipient recipient: DEUploadRecipient, boundary: String) {
        self.append(byBoundary: boundary)
        
        self.append(byHeaderField: .createMultipartFormDispositionItem(named: "peer"))
        self.append(byHeaderField: .init(name: .contentType,
                                         value: .init("text/plaing"),
                                         attrs: ["charset" : "UTF-8"]))
        self.append(byLineBreaks: 1)
        self.append(byString: recipient.mulitpartFormPeerDescription)
    }
}
