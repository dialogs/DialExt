//
//  DEUti.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 21/08/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import MobileCoreServices

public struct DEUti: RawRepresentable {
    
    public typealias RawValue = String
    
    public let rawValue: RawValue
    
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: RawValue) {
        self.init(rawValue: rawValue)
    }
    
    /// Creates UTI with given mimetype.
    public init?(mimeType: String, allowUnknownTags: Bool = true, utiToConform: String? = nil) {
        var utiToConfrormCFString: CFString? = nil
        if let utiToConform = utiToConform {
            utiToConfrormCFString = utiToConform as CFString
        }
        
        if let unmanagedRawValue = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType,
                                                             mimeType as CFString,
                                                             utiToConfrormCFString) {
            let rawValue = unmanagedRawValue.takeRetainedValue() as String
            if allowUnknownTags || rawValue.hasPrefix("dyn") {
                self.init(rawValue)
            }
        }
        return nil
    }
    
    public var fileExtension: String? {
        if let foundExtensionUnmanaged = UTTypeCopyPreferredTagWithClass(self.rawValue as CFString,
                                                                         kUTTagClassFilenameExtension) {
            return foundExtensionUnmanaged.takeRetainedValue() as String
        }
        return nil
    }
    
    public var mimeType: String? {
        if let foundExtensionUnmanaged = UTTypeCopyPreferredTagWithClass(self.rawValue as CFString,
                                                                         kUTTagClassMIMEType) {
            return foundExtensionUnmanaged.takeRetainedValue() as String
        }
        return nil
    }
    
    public static let png = DEUti.init(kUTTypePNG as String)
    
    public static let jpeg = DEUti.init(kUTTypeJPEG as String)
    
    public static let plainText = DEUti.init(kUTTypePlainText as String)
    
    public static func fileExtension(uti: String) -> String? {
        if let foundExtensionUnmanaged = UTTypeCopyPreferredTagWithClass(uti as CFString,
                                                                         kUTTagClassFilenameExtension) {
            return foundExtensionUnmanaged.takeRetainedValue() as String
        }
        return nil
    }
    
}
