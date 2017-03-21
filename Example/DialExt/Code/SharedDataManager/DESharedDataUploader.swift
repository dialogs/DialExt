//
//  DESharedDataUploader.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 16/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public typealias DESharedDataUploadCompletion = ((Bool, Error?) -> ())

public protocol DESharedDataUploader {
    func upload(_ data: Data, token: String, targetId: Int, completion: DESharedDataUploadCompletion?)
}


public class DEBasicSharedDataUploader: DESharedDataUploader {
    
    public func upload(_ data: Data, token: String, targetId: Int, completion: DESharedDataUploadCompletion?) {
        fatalError("Unprepared yet")
    }
    
}

public class DEDebugSharedDataUploader: DESharedDataUploader {
    
    public enum Config {
        case performWithSuccess
        case performWithFailure(Error?)
    }
    
    public var config: Config = .performWithSuccess
    
    public func upload(_ data: Data, token: String, targetId: Int, completion: DESharedDataUploadCompletion?) {
        switch self.config {
        case .performWithSuccess:
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1000, execute: { 
                completion?(true, nil)
            })
        case let .performWithFailure(error):
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1000, execute: {
                completion?(false, error)
            })
        }
    }
    
}
