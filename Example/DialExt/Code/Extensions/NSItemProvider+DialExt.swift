//
//  NSItemProvider+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 20/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

import MobileCoreServices

public enum DEItemProviderError: Error {
    case failToRepresent
}

public extension NSItemProvider {
    
    public var isDataRepresentable: Bool {
        return self.hasItemConformingToTypeIdentifier(kUTTypeData as String)
    }
    
    public var mimeRepresentableTypeIdentifiers: [String] {
        let filtered: [String] = self.registeredTypeIdentifiers.compactMap({
            guard let _ = UTTypeCopyPreferredTagWithClass($0 as CFString, kUTTagClassMIMEType)?.takeRetainedValue() else {
                return nil
            }
            
            return $0
        })
        return filtered
    }
    
    public var supposedMimeType: String? {
        for case let uti as CFString in self.registeredTypeIdentifiers {
            if let foundExtensionUnmanaged = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType) {
                return foundExtensionUnmanaged.takeRetainedValue() as String
            }
        }
        return nil
    }
    
    public var supposedFileExtension: String? {
        for case let uti as CFString in self.registeredTypeIdentifiers {
            if let foundExtensionUnmanaged = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension) {
                return foundExtensionUnmanaged.takeRetainedValue() as String
            }
        }
        return nil
    }
    
    public enum DataLoadingResult {
        case success(ItemType)
        case failure(Error)
    }
    
    public enum ItemType {
        case data(Data)
        case urlData(url: URL, data: Data)
        case image(UIImage)
    }
    
    @discardableResult public func loadData(options: [AnyHashable : Any]?,
                                            onSuccess: @escaping ((ItemType) -> ()),
                                            onFailure: @escaping ((Error) -> ())) -> Bool {
        let typeId = kUTTypeData as String
        guard self.hasItemConformingToTypeIdentifier(typeId) else {
            return false
        }
        
        self.loadItem(forTypeIdentifier: kUTTypeData as String, options: options) { (encodedValue, error) in
            guard let value = encodedValue else {
                onFailure(error ?? NSError.unknown())
                return
            }
            
            switch value {
                
            case let data as Data:
                onSuccess(.data(data))
                
            case let image as UIImage:
                onSuccess(.image(image))
                
            case let url as URL:
                DispatchQueue.global(qos: .background).async {
                    do {
                        let data = try Data.init(contentsOf: url)
                        onSuccess(.urlData(url: url, data: data))
                    }
                    catch {
                        onFailure(error)
                    }
                }
                
            default: onFailure(DEUploadError.unrecognizableExtensionItem)
            }
        }
        
        return true
    }
    
    @discardableResult public func loadItemData(options: [AnyHashable : Any]?,
                                                completionHandler: NSItemProvider.CompletionHandler?) -> Bool {
        let typeId = kUTTypeData as String
        guard self.hasItemConformingToTypeIdentifier(typeId) else {
            return false
        }
        self.loadItem(forTypeIdentifier: typeId, options: options, completionHandler: completionHandler)
        return true
    }
    
    @discardableResult public func loadAndRepresentData(options: [AnyHashable : Any]?,
                                                        completionHandler: ((Data?, Error?)->())?) -> Bool {
        return self.loadItemData(options: options, completionHandler: { (result, error) in
            switch result {
            case let data as Data:
                completionHandler?(data, nil)
                
            case let url as URL:
                DispatchQueue.global(qos: .utility).async {
                    let data: Data
                    do {
                        data = try Data.init(contentsOf: url)
                    }
                    catch {
                        completionHandler?(nil, error)
                        return
                    }
                    
                    completionHandler?(data, nil)
                }
            default:
                completionHandler?(nil, DEItemProviderError.failToRepresent)
                break
            }
        })
    }
}
