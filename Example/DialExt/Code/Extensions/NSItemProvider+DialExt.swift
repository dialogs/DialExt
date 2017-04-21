//
//  NSItemProvider+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 20/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

//import MobileCoreServices

public extension NSItemProvider {
    
    public var isDataRepresentable: Bool {
        return true
//        return self.hasItemConformingToTypeIdentifier(kUTTypeData as String)
    }
    
//    public var supposedFileExtension: String? {
//        
//        for case let uti as CFString in self.registeredTypeIdentifiers {
//            if let foundExtensionUnmanaged = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension) {
//                return foundExtensionUnmanaged.takeRetainedValue() as String
//            }
//        }
//        return nil
//    }
    
}
