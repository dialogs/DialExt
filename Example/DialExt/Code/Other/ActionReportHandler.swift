//
//  ActionReportHandler.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 18/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public typealias DEActionReportHandler = ((_ instance: Any?, _ action: String, _ userInfo: [String:Any]?) -> ())
