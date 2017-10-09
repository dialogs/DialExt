//
//  DEHttpError.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 24/05/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public extension NSError {
    
    public static let DEHttpErrorDomain = "im.dlg.error.domain.http"
    
    public class func httpError(statusCode: Int, userInfo: [String : Any]? = nil) -> NSError {
        return self.init(domain: DEHttpErrorDomain, code: statusCode, userInfo: userInfo)
    }
    
    public class func httpError(statusCode: Int, data: Data?) -> NSError {
        var descr = "Unexpected response status code: \(statusCode)."
        if let responseData = data, let responseString = String.init(data: responseData, encoding: .utf8) {
            descr.append(" Response: \(responseString)")
        }
        return self.httpError(statusCode: statusCode, userInfo: [NSLocalizedDescriptionKey : descr])
    }
    
}
