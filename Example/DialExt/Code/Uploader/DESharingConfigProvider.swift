//
//  DESharingApiUrlProvider.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 10/07/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

protocol DESharingConfigProvider {
    func getSharingApiUrl() throws -> URL
    func getSharingContainerName() throws -> String
}

protocol DEWriteableSharingConfigProvider: DESharingConfigProvider {
    func setSharingApiUrl(_ url: URL) throws
    func setSharingContainerName(_ name: String) throws
}


extension DEGroupedKeychainDataProvider: DEWriteableSharingConfigProvider {
    
    func setSharingContainerName(_ name: String) throws {
        let data = name.data(using: .utf8)! as NSData
        try self.addOrUpdateData(query: .writeShared(.sharingContainerName, data: data))
    }
    
    func getSharingContainerName() throws -> String {
        let data = try self.readData(query: .readShared(.sharingContainerName))
        guard let name = String(data: data, encoding: .utf8) else {
            throw DEUploadError.noContactsShared
        }
        return name
    }

    
    func getSharingApiUrl() throws -> URL {
        let data = try self.readData(query: .readShared(.sharingApiService))
        
        guard let link = String.init(data: data, encoding: .utf8) else {
            throw DEUploadError.noServerApiURL
        }
        guard let url = URL.init(string: link) else {
            throw DEUploadError.invalidServerApiURL
        }
        return url
    }
    
    func setSharingApiUrl(_ url: URL) throws {
        let link = url.absoluteString
        let data = link.data(using: .utf8)! as NSData
        try self.addOrUpdateData(query: .writeShared(.sharingApiService, data: data))
    }

    
    
}

fileprivate extension DEKeychainQuery.Service {
    
    fileprivate static let sharingApiService = DEKeychainQuery.Service.init("im.dlg.sharing.api_url")
    
    fileprivate static let sharingContainerName = DEKeychainQuery.Service.init("im.dlg.sharing.container")
}

