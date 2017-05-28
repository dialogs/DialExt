//
//  DEUploadDataRepresentation.swift
//  Pods
//
//  Created by Aleksei Gordeev on 27/05/2017.
//
//

import Foundation
import MobileCoreServices

/**
    Describes data's content without specific details.
 */
public class DEUploadDataRepresentation {
    
    public let mimeType: String
    
    public let data: Data
    
    public let fileExtension: String
    
    public enum Source: Equatable {
        case generated
        case url(URL)
        
        public static func ==(lhs: Source, rhs: Source) -> Bool {
            switch (lhs, rhs) {
            case (.generated, .generated): return true
            case let (.url(lhsUrl), .url(rhsUrl)): return lhsUrl == rhsUrl
            default: return false
            }
        }
    }
    
    public init(data: Data, mimeType: String, fileExtension: String) {
        self.mimeType = mimeType
        self.fileExtension = fileExtension
        
        self.data = data
    }
    
    convenience public init(data: Data, uti: String) {
        let mimeType = UTTypeCopyPreferredTagWithClass(uti as CFString, kUTTagClassMIMEType)!.takeRetainedValue()
        var fileExtension: String = ""
        if let proposedExtension = UTTypeCopyPreferredTagWithClass(uti as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue() {
            fileExtension = proposedExtension as String
        }

        self.init(data: data, mimeType: mimeType as String, fileExtension: fileExtension as String)
    }
    
    convenience public init(data: Data) {
        self.init(data: data, uti: kUTTypeData as String)
    }
    
}
