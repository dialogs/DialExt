//
//  DECryptoSharedSecretProvider.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 17/08/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation


public protocol DECryptoSharedSecretProvider {
    func requestSharedSecret(clientPublicKey: Data, completion: (SharedSecret) -> ())
}
