//
//  DECryptoIncomingDataDecryptorTests.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 21/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
import DLGSodium
@testable import DialExt

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
        
        
        let message = "Test message 1357444444Ghtgeagegklfkgpgn)"
        let encodedMessage: Data = sodium.secretBox.seal(message: message.data(using: .utf8)!, secretKey: serverSharedSecret.tx)!
        
        guard let decodedMessageData = sodium.secretBox.open(nonceAndAuthenticatedCipherText: encodedMessage,
                                                             secretKey: clientSharedSecret.rx) else {
                                                                XCTFail("Fail to decrypt message data")
                                                                return
        }
        guard let decodedMessage = String.init(data: decodedMessageData, encoding: .utf8) else {
            XCTFail("Fail to decode message")
            return
        }
        
        XCTAssertEqual(message, decodedMessage)
    }
    
    func testClientAndServerSharedSecretKey() {
        let sodium = Sodium()!
        let clientKeys = sodium.keyExchange.keyPair(seed: sodium.randomBytes.buf(length: 32)!)!
        let serverKeys = sodium.keyExchange.keyPair(seed: sodium.randomBytes.buf(length: 32)!)!
        
        let clientSharedSecret = sodium.keyExchange.sessionKeyPair(publicKey: clientKeys.publicKey,
                                                                   secretKey: clientKeys.secretKey,
                                                                   otherPublicKey: serverKeys.publicKey,
                                                                   side: .client)!
        
        let serverSharedSecret = sodium.keyExchange.sessionKeyPair(publicKey: serverKeys.publicKey,
                                                                   secretKey: serverKeys.secretKey,
                                                                   otherPublicKey: clientKeys.publicKey,
                                                                   side: .server)!
        
        XCTAssertEqual(clientSharedSecret.rx, serverSharedSecret.tx)
        XCTAssertEqual(clientSharedSecret.tx, serverSharedSecret.rx)
    }
    
    func testServerPreparedData() {
        
        // Given
        //        let nonce: DEInt64BasedNonce = DEInt64BasedNonce.init(value: -2622849142741802)
        let nonceData = "ffe550ae7fdabfde00000000000000000000000000000000".de_encoding(.hex)!
        
        // Shared secret client-part for reading
        let rx = "08d9a5527f22de29c6fa11c7ee61dd0ae007586b471553938c0cb859cf35cce3".de_encoding(.hex)!
        
        // When
        let message = "7ccac760305e29a62d64ee3140d2cdd068714e9d15859bf359a9bc86fc06ba2e27b290c1cab0ebc0dc34f25a92811141c90f7a7889e99a6008b3e575cf".de_encoding(.hex)!
        let expectedMessage = "796a6d73626f3038336468707a7a767770347978757972516b6b7369416775634a656574736c6f676173636b71".de_encoding(.hex)!
        
        // Then
        guard let decryptedMessage = try? self.decryptor.decrypt(incomingData: message, rx: rx, nonceData: nonceData) else {
            XCTFail("Fail to decrypt message")
            return
        }
        
        XCTAssertEqual(decryptedMessage, expectedMessage)
    }
    
    func testSharedSecretGeneration() {
        let sodium = Sodium.init()!
        
        let clientPublic = "dc2efbd4fcdc2c4f8e8ae87ae4806d1f96b1d27e10cf1f44b2d8992c65cac41b".de_encoding(.hex)!
        let clientSecret = "4051cf96730d0ac21be63698b032bcb1e7ab5c7ea520dea4a72865d451ba1d52".de_encoding(.hex)!
        let clientKeys = KeyExchange.KeyPair.init(publicKey: clientPublic, secretKey: clientSecret)
        
        let serverPublic = "f61788dd49d78f061a48adf45128be1693f6099c52d3cb9ae69f87b7ba11620c".de_encoding(.hex)!
        let serverSecret = "a7a91bbe84f15da821a5421d2a96c93c575138dee2bbaca11a818e5aeed72a49".de_encoding(.hex)!
        let serverKeys = KeyExchange.KeyPair.init(publicKey: serverPublic, secretKey: serverSecret)
        
        let clientSharedSecret = sodium.keyExchange.sessionKeyPair(publicKey: clientKeys.publicKey,
                                                                   secretKey: clientKeys.secretKey,
                                                                   otherPublicKey: serverKeys.publicKey,
                                                                   side: .client)!
        
        let serverSharedSecret = sodium.keyExchange.sessionKeyPair(publicKey: serverKeys.publicKey,
                                                                   secretKey: serverKeys.secretKey,
                                                                   otherPublicKey: clientKeys.publicKey,
                                                                   side: .server)!
        
        XCTAssertEqual(clientSharedSecret.rx,
                       "79b5fe6746853894f60d76e40487072c2af8ef01c1b34d606e804b5d3dab1de9".de_encoding(.hex))
        XCTAssertEqual(clientSharedSecret.tx,
                       "09bae6d4fc5b2dbc48558c8c8a4e67dcf6611561aaea6a16897bcb8aa23d4fa1".de_encoding(.hex))
        
        XCTAssertEqual(clientSharedSecret.tx, serverSharedSecret.rx)
        XCTAssertEqual(clientSharedSecret.rx, serverSharedSecret.tx)
        
        XCTAssertNotEqual(clientSharedSecret.rx, clientSharedSecret.tx)
    }
    
    
    func testServerPreparedMessageDecoding() {
        let encodedMessage = "d2043c71565871034d618b878cd7927761600b5854d38f4b86c168b4fca34dc30ae31c2e751d9b04139b0bf225db16b9570d1d4ad2f22ad6acebfddef5".de_encoding(.hex)!
        let nonce = DEInt64BasedNonce.init(-2792862357897823)
        guard let decodedMessage = Sodium()!.secretBox.open(authenticatedCipherText: encodedMessage,
                                                            secretKey: Session.defaultClient.sharedSecret.rx,
                                                            nonce: nonce.bigEndianData) else {
                                                                XCTFail("Fail to decrypt message")
                                                                return
        }
        
        let expectedMessage = "121d426c616b6520536e796465725f313630353734323536343a2054455354220c746573742067726f75702031".de_encoding(.hex)!
        XCTAssertEqual(decodedMessage, expectedMessage)
    }
    
    struct SessionPair {
        
        static let `default` = SessionPair.init(clientSession: Session.defaultClient,
                                                serverSession: Session.defaultServer)
        
        let clientSession: Session
        let serverSession: Session
    }
    
    struct Session {
        
        static let defaultClient: Session = {
            let clientKeys = KeyExchange.KeyPair.testClientKeyPair
            let serverPublic = KeyExchange.KeyPair.testServerKeyPair.publicKey
            let secret = clientKeys.sharedSecret(otherPublicKey: serverPublic, side: .client)
            return Session.init(side: .client, keyPair: clientKeys, sharedSecret: secret)
        }()
        
        static let defaultServer: Session = {
            let serverKeys = KeyExchange.KeyPair.testServerKeyPair
            let clientKey = KeyExchange.KeyPair.testClientKeyPair.publicKey
            let secret = serverKeys.sharedSecret(otherPublicKey: clientKey, side: .server)
            return Session.init(side: .server, keyPair: serverKeys, sharedSecret: secret)
        }()
        
        var side: KeyExchange.Side
        var keyPair: KeyExchange.KeyPair
        var sharedSecret: KeyExchange.SessionKeyPair
    }
    
    /*
     client public:
     dc2efbd4fcdc2c4f8e8ae87ae4806d1f96b1d27e10cf1f44b2d8992c65cac41b
     
     client secret:
     4051cf96730d0ac21be63698b032bcb1e7ab5c7ea520dea4a72865d451ba1d52
     
     server public:
     f61788dd49d78f061a48adf45128be1693f6099c52d3cb9ae69f87b7ba11620c
     
     server secret:
     a7a91bbe84f15da821a5421d2a96c93c575138dee2bbaca11a818e5aeed72a49
     
     
     rx:
     79b5fe6746853894f60d76e40487072c2af8ef01c1b34d606e804b5d3dab1de9
     
     tx:
     09bae6d4fc5b2dbc48558c8c8a4e67dcf6611561aaea6a16897bcb8aa23d4fa1
     */
    
    func testServerPreparedData2() {
        
        var data = Data.init(count: 32)
        for var i in 0..<32 {
            withUnsafeBytes(of: &i, {
                data[i] = $0.first!
            })
        }
        
        let sodium = Sodium.init()!
        
        let clientKeys = sodium.keyExchange.keyPair(seed: sodium.randomBytes.buf(length: 32)!)!
        
        
        let clientSecretKey = clientKeys.secretKey
        let clientPublicKey = clientKeys.publicKey
        print("client public: \(clientPublicKey)")
        print("client secret: \(clientSecretKey)")
        
        let serverPublicKey = "f61788dd49d78f061a48adf45128be1693f6099c52d3cb9ae69f87b7ba11620c".de_encoding(.hex)!
        let serverSecretKey = "a7a91bbe84f15da821a5421d2a96c93c575138dee2bbaca11a818e5aeed72a49".de_encoding(.hex)!
        
        let clientSharedSecret = sodium.keyExchange.sessionKeyPair(publicKey: clientPublicKey,
                                                                   secretKey: clientSecretKey,
                                                                   otherPublicKey: serverPublicKey,
                                                                   side: .client)!
        
        let fakeClientPublicKey = "dc2efbd4fcdc2c4f8e8ae87ae4806d1f96b1d27e10cf1f44b2d8992c65cac41b".de_encoding(.hex)!
        let serverSharedSecret = sodium.keyExchange.sessionKeyPair(publicKey: serverPublicKey,
                                                                   secretKey: serverSecretKey,
                                                                   otherPublicKey: fakeClientPublicKey,
                                                                   side: .server)!
        
        let expectedRx = "c0e4e5005d9f959f54563d8a9e3e3a06ea53b25c912fe4fc165a3e8771a8f2e6".de_encoding(.hex)!
        //        XCTAssertEqual(clientSharedSecret.rx,
        //                       "1993604d3d5f68ffc081f9fcea6fb1ed1f183e48dff0cfa18833a61af04997d5".de_encoding(.hex))
        //        XCTAssertEqual(clientSharedSecret.tx,
        //                       "c0e4e5005d9f959f54563d8a9e3e3a06ea53b25c912fe4fc165a3e8771a8f2e6".de_encoding(.hex))
        
        
        let msg = "121c49736169616820486f726e5f313532313331323832353a2054455354220c746573742067726f75702031".de_encoding(.hex)!
        let nonce = DEInt64BasedNonce.init(1007)
        // Then
        
    }
    
}


extension KeyExchange.KeyPair {
    
    static let testClientKeyPair = KeyExchange.KeyPair.init(publicKey:
        "dc2efbd4fcdc2c4f8e8ae87ae4806d1f96b1d27e10cf1f44b2d8992c65cac41b".de_encoding(.hex)!,
                                                            secretKey:
        "4051cf96730d0ac21be63698b032bcb1e7ab5c7ea520dea4a72865d451ba1d52".de_encoding(.hex)!)
    
    static let testServerKeyPair = KeyExchange.KeyPair.init(publicKey:
        "f61788dd49d78f061a48adf45128be1693f6099c52d3cb9ae69f87b7ba11620c".de_encoding(.hex)!,
                                                            secretKey:
        "a7a91bbe84f15da821a5421d2a96c93c575138dee2bbaca11a818e5aeed72a49".de_encoding(.hex)!)
    
    public func sharedSecret(otherPublicKey: Data, side: KeyExchange.Side) -> KeyExchange.SessionKeyPair {
        return Sodium()!.keyExchange.sessionKeyPair(publicKey: self.publicKey,
                                                    secretKey: self.secretKey,
                                                    otherPublicKey: otherPublicKey, side: side)!
    }
}
