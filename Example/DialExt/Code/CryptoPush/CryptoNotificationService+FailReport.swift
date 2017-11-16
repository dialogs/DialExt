//
//  CryptoNotificationService+FailReport.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 16/11/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension CryptoNotificationService {
    
    public struct FailReport: CustomStringConvertible {
        
        internal static let userInfoKey: String = "im.dlg.crypto.fail_report"
        
        public let error: Error
        public var nonce: String? = nil
        
        public static func with(error: Error) -> FailReport {
            return FailReport.init(error: error, nonce: nil)
        }
        
        private struct Entry: CustomStringConvertible {
            let name: String
            let value: String
            
            init(_ name: String, _ value: String) {
                self.name = name
                self.value = value
            }
            
            var description: String {
                return "\(name): \(value)"
            }
        }
        
        private var entries: [Entry] {
            var entries: [Entry] = []
            entries.append(Entry.init("Error", error.localizedDescription))
            if let nonce = self.nonce {
                entries.append(Entry.init("Nonce", nonce))
            }
            return entries
        }
        
        public var description: String {
            return entries.map({$0.description}).joined(separator: ", ")
        }
        
    }
    
}

