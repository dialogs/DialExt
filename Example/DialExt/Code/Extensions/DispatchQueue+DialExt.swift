//
//  DispatchQueue+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 10/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public func de_perform(code: (()->())?, on queue: DispatchQueue?, sync: Bool = false) {
    guard let codeToPerform = code else {
        return
    }
    
    if let targetQueue = queue {
        if sync {
            targetQueue.sync(execute: codeToPerform)
        }
        else {
            targetQueue.async(execute: codeToPerform)
        }
    }
    else {
        codeToPerform()
    }
}
