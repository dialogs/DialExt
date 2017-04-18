//
//  DEGroupContainerItemBindedRepresenter+Queuer.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 12/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//


public extension DEGroupContainerItemBindedRepresenter {
    
    public typealias Queuer = DEGroupContainerItemBindedRepresenterQueuer<Representation>
    
    public func createQueuer() -> Queuer {
        return Queuer.init(representer: self)
    }
}
