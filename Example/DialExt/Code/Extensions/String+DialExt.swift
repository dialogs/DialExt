//
//  String+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 17/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension String {
    
    public mutating func append(byNewLines count: Int = 1) {
        let newLines = String(repeating: "\r\n", count: count)
        self.append(newLines)
    }
    
    public func appending(byNewLines count: Int = 1) -> String {
        var string = self
        string.append(byNewLines: count)
        return string
    }
    
    public func isLink() -> Bool {
        let types: NSTextCheckingResult.CheckingType = [.link]
        let detector = try? NSDataDetector(types: types.rawValue)
        guard (detector != nil && self.count > 0) else { return false }
        if detector!.numberOfMatches(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.count)) > 0 {
            return true
        }
        return false
    }
    
    public func attributed(with attributes: [String : Any]?) -> NSAttributedString {
        if let attributes = attributes {
            var newAttributes: [NSAttributedStringKey : Any] = [:]
            for entry in attributes {
                newAttributes[NSAttributedStringKey.init(entry.key)] =  entry.value
            }
            return NSAttributedString.init(string: self, attributes: newAttributes)
        }
        return NSAttributedString.init(string: self, attributes: nil)
    }
    
    #if swift(>=4.0)
    public func attributed(_ attributes: [NSAttributedStringKey : Any]?) -> NSAttributedString {
        return NSAttributedString.init(string: self, attributes: attributes)
    }
    #endif

    /// Expanded encoding
    ///
    /// - hex: Hex string of bytes
    /// - base64: Base64 string
    public enum ExpandedEncoding {
        /// Hex string of bytes
        case hex
        /// Base64 string
        case base64
    }
    
    /// Convert to `Data` with expanded encoding
    ///
    /// - Parameter encoding: Expanded encoding
    /// - Returns: data
    public func de_encoding(_ encoding: ExpandedEncoding) -> Data? {
        switch encoding {
        case .hex:
            guard self.count % 2 == 0 else { return nil }
            var data = Data(capacity: self.count/2)
            var byteLiteral = ""
            for (index, character) in self.enumerated() {
                if index % 2 == 0 {
                    byteLiteral = String(character)
                } else {
                    byteLiteral.append(character)
                    guard let byte = UInt8(byteLiteral, radix: 16) else { return nil }
                    data.append(byte)
                }
            }
            return data
        case .base64:
            return Data(base64Encoded: self)
        }
    }
}
