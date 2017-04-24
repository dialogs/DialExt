//
//  Localization.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 24/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation


public func DELocalize(_ localizable: DELocalizable) -> String! {
    return DELocalize(localizable.rawValue)
}

/**
 * Returns localized string found in bundles in following order:
 * Main bundle, then bundles in registered bundles (in order they were registered), framework bundle.
 */
public func DELocalize(_ text: String!) -> String! {
    guard text != nil else {
        return nil
    }
    
    let appLocalizedString = NSLocalizedString(text, comment: "")
    
    if (appLocalizedString != text) {
        return appLocalizedString
    }
    
    for table in tables {
        if let customLocalizedString = table.localized(text: text), customLocalizedString != text {
            return customLocalizedString
        }
    }
    
    return NSLocalizedString(text, tableName: nil, bundle: Bundle.dialExtResourcesBundle, value: text, comment: "")
}

public extension String {
    public init(_ loc: DELocalizable) {
        self = loc.localized
    }
}

public struct DELocalizable : RawRepresentable, Equatable, Hashable, Comparable {
    
    // MARK: - Content
    
    public private(set) var rawValue: String
    
    public init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public var hashValue: Int {
        return self.rawValue.hash
    }
    
    public static func ==(lhs: DELocalizable, rhs: DELocalizable) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    public static func <(lhs: DELocalizable, rhs: DELocalizable) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public var localized: String! {
        return DELocalize(self)
    }
    
    
    public static let alertCancel = DELocalizable("AlertCancel")
    
    public static let alertUploadProgress = DELocalizable("AlertUploadProgress")
    
    public static func alertUploadProgress(progress: Float) -> String {
        let percentage = Int(progress * 100.0)
        return DELocalize(.alertUploadProgress) + "\(percentage) %"
    }
    
    public static let alertUploadTitle = DELocalizable("AlertUploadTitle")
    
    public static let alertUploadPreparing = DELocalizable("AlertUploadPreparing")
    
    public static let alertUploadFinished = DELocalizable("AlertUploadFinished")
    
}


/**
 * Registers bundle's table.
 */
public func DERegisterLocalizedBundle(_ table: String, bundle: Bundle) {
    if !tables.contains(where: { $0.table == table} ) {
        tables.append(LocalizationTable(table: table, bundle: bundle))
    }
}

private var tables = [LocalizationTable]()

private class LocalizationTable {
    
    let table: String
    let bundle: Bundle
    
    init(table: String, bundle: Bundle) {
        self.table = table
        self.bundle = bundle
    }
    
    func localized(text: String, comment: String? = nil) -> String? {
        return NSLocalizedString(text, tableName: self.table, bundle: self.bundle, value: text, comment: "")
    }
}
