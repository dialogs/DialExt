//
//  DECryptoIncomingDataDecryptorTests.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 21/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
import DialExt
import DLGSodium

class DECryptoIncomingDataDecryptorTests: XCTestCase {
    
    let decryptor: DECryptoIncomingDataDecryptor = DECryptoIncomingDataDecryptor.init()
    
    func testSelfEncryptedMessage() {
        let sodium = Sodium.init()!
        
        let serverKeys = sodium.keyExchange.keyPair(seed: sodium.randomBytes.buf(length: 32)!)!
        let clientKeys = sodium.keyExchange.keyPair(seed: sodium.randomBytes.buf(length: 32)!)!
        XCTAssertNotEqual(serverKeys.publicKey, clientKeys.publicKey)
        XCTAssertNotEqual(serverKeys.secretKey, clientKeys.secretKey)
        
        let serverSharedSecret = sodium.keyExchange.sessionKeyPair(publicKey: serverKeys.publicKey,
                                                                   secretKey: serverKeys.secretKey,
                                                                   otherPublicKey: clientKeys.publicKey,
                                                                   side: .server)!
        
        let clientSharedSecret = sodium.keyExchange.sessionKeyPair(publicKey: clientKeys.publicKey,
                                                                   secretKey: clientKeys.secretKey,
                                                                   otherPublicKey: serverKeys.publicKey,
                                                                   side: .client)!
        
        XCTAssertEqual(serverSharedSecret.rx, clientSharedSecret.tx)
        XCTAssertEqual(serverSharedSecret.tx, clientSharedSecret.rx)
        XCTAssertNotEqual(serverSharedSecret.rx, clientSharedSecret.rx)
        
        let nonce = Int64(-2622849142741802).bigEndian
        var nonceData = Data.de_withValue(nonce)
        nonceData.appendByZeros(toLength: 24)
        
        let message = "Test message 1357444444Ghtgeagegklfkgpgn)"
        let encodedMessage: Data = sodium.secretBox.seal(message: message.data(using: .utf8)!, secretKey: serverSharedSecret.tx)!
        
        guard let decodedMessage = sodium.secretBox.open(authenticatedCipherText: encodedMessage,
                                                      secretKey: clientSharedSecret.rx,
                                                      nonce: nonceData) else {
            
        }
    }
    
    func testServerPreparedData() {
        
        // Given
        //        let nonce: DEInt64BasedNonce = DEInt64BasedNonce.init(value: -2622849142741802)
        let nonceData = "ffe550ae7fdabfde00000000000000000000000000000000".de_encoding(.bytesHexLiteral)!
        
        // Shared secret client-part for reading
        let rx = "08d9a5527f22de29c6fa11c7ee61dd0ae007586b471553938c0cb859cf35cce3".de_encoding(.bytesHexLiteral)!
        
        // When
        let message = "7ccac760305e29a62d64ee3140d2cdd068714e9d15859bf359a9bc86fc06ba2e27b290c1cab0ebc0dc34f25a92811141c90f7a7889e99a6008b3e575cf".de_encoding(.bytesHexLiteral)!
        let expectedMessage = "796a6d73626f3038336468707a7a767770347978757972516b6b7369416775634a656574736c6f676173636b71".de_encoding(.bytesHexLiteral)!
        
        // Then
        guard let decryptedMessage = try? self.decryptor.decrypt(incomingData: message, rx: rx, nonceData: nonceData) else {
            XCTFail("Fail to decrypt message")
            return
        }
        
        XCTAssertEqual(decryptedMessage, expectedMessage)
    }
}
