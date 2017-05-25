//
//  DEHttpRequestBodyFile.swift
//  Pods
//
//  Created by Aleksei Gordeev on 24/05/2017.
//
//

import Foundation

extension DEHttpRequestBody {
    
    public struct File: DEHttpRequestBodyItemRepresentable {
        
        public static let defaultName = "file"
        
        public static let defaultMimeType = "application/octet-stream"
        
        public var name: String
        
        public var filename: String?
        
        public var mimeType: String
        
        public var data: Data
        
        public init(name: String = File.defaultName,
                    quoteName: Bool = true,
                    filename: String? = nil,
                    quoteFilename: Bool = true,
                    mimeType: String = File.defaultMimeType,
                    data: Data) {
            self.name = quoteName ? name.wrappingByQuotes() : name
            self.filename =  quoteFilename ? filename?.wrappingByQuotes() : filename
            self.mimeType = mimeType
            self.data = data
        }
        
        public var bodyItems: [DEHttpRequestBodyItemRepresentable] {
            let contentDisposition = DEHttpRequestBody.HeaderFieldEntry.createMultipartFormFile(name: self.name,
                                                                                                filename: self.filename)
            let contentType = DEHttpRequestBody.HeaderFieldEntry.init(name: HeaderFieldName.contentType,
                                                                      value: HeaderFieldValue.init(rawValue: self.mimeType))
            
            let items: [DEHttpRequestBodyItemRepresentable] = [
                contentDisposition, String.httpRequestBodyLineBreak,
                contentType, String.httpRequestBodyLineBreak,
                String.httpRequestBodyLineBreak,
                self.data
            ]
            return items
        }
        
        public var httpRequestBodyData: Data {
            var data: Data = Data.init()
            self.bodyItems.forEach({data.append($0.httpRequestBodyData)})
            return data
        }
        
        public var httpRequestBodyDescription: String {
            let descriptions: [String] = self.bodyItems.map({ $0.httpRequestBodyDescription})
            return descriptions.joined()
        }
        
    }
    
}
