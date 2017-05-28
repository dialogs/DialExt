//
//  DEUploadDetailedDataRepresentation.swift
//  Pods
//
//  Created by Aleksei Gordeev on 27/05/2017.
//
//

import Foundation


public typealias DEUploadImageRepresentation = DEUploadDetailedDataRepresentation<DEUploadImageDetails>

public typealias DEUploadVideoRepresentation = DEUploadDetailedDataRepresentation<DEUploadVideoDetails>

public typealias DEUploadAudioRepresentation = DEUploadDetailedDataRepresentation<DEUploadAudioDetails>


public class DEUploadDetailedDataRepresentation<Details> {
    
    let dataRepresentation: DEUploadDataRepresentation
    
    let details: Details
    
    public init(dataRepresentation: DEUploadDataRepresentation, details: Details) {
        self.dataRepresentation = dataRepresentation
        self.details = details
    }
    
    public func filename(base: String) -> String {
        var filename = base
        if !dataRepresentation.fileExtension.isEmpty {
            filename = filename.appending(".").appending(dataRepresentation.fileExtension)
        }
        return filename
    }
}

public struct DEUploadImageDetails {
    public var size: DEUploadIntegerSize
}


public struct DEUploadVideoDetails {
    public var size: DEUploadIntegerSize
    public var durationInSeconds: Int
}

public struct DEUploadAudioDetails {
    public var durationInSeconds: Int
}
