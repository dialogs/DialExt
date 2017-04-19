//
//  Bundle+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 19/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

extension Bundle {
    
    func allResources() -> [URL] {
        // Enumerators are recursive
        guard let enumerator = FileManager.default.enumerator(atPath: self.bundlePath) else {
            return []
        }
        
        var filePaths: [URL] = []
        
        while let object = enumerator.nextObject() {
            if let path = object as? String {
                filePaths.append(bundleURL.appendingPathComponent(path))
            }
        }
        
        return filePaths
    }
    
    func hasStoryboard(named: String) -> Bool {
        return self.path(forResource: named, ofType: "storyboardc") != nil
    }
    
}
