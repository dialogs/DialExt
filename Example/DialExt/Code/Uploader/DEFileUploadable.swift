//
//  DEFileUploadable.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 14/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension DEFileUploader {
    
    public struct File {
        
        public let name: String
        
        public let data: Data
        
        public let mimetype: String
        
        public init(name: String, data: Data, mimetype: String) {
            self.name = name
            self.data = data
            self.mimetype = mimetype
        }
        
    }   
}

