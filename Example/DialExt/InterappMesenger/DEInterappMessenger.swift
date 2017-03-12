//
//  DEInterappMessenger.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 10/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation


/**
 *
 */
public class DEInterappMessengeEncoder<DEInterappMessage> {
    
    func encode(message: DEInterappMessage) throws -> Data {
        fatalError()
    }
    
    func decode(data: Data) throws -> DEInterappMessage {
        fatalError()
    }
    
}


public class DEInterappMessenger<Message> {
    
    public typealias Encoder = DEInterappMessengeEncoder<Message>
    
    private let item: DEGroupContainerItem
    
    private let encoder: Encoder
    
    public init(sharedItem: DEGroupContainerItem, encoder: Encoder) {
        self.item = sharedItem
        self.encoder = encoder
        
        self.item.onDidChange = { [weak self] in
            withExtendedLifetime(self, {
                guard let strongSelf = self else {
                    return
                }
                strongSelf.checkMessage()
            })
        }
    }
    
    public var onRecieveMessage:((Message?)->())? = nil
    
    public var onDidFailToEncodeMessage:((Error?) -> ())? = nil
    
    public func sendMessage(_ message: Message, onFinish:(Bool, Error?)) throws {
        let data = try self.encoder.encode(message: message)
        item.writeData(data, onFinish: onFinish)
    }
    
    private func checkMessage() {
        self.item.readData({ [weak self] data in
            
            withExtendedLifetime(self, {
                guard let strongSelf = self else {
                    return
                }
                strongSelf.didReadMessageData(data)
            })
            
        }) { [weak self] (error) in
            withExtendedLifetime(self, {
                guard let strongSelf = self else {
                    return
                }
                strongSelf.didFailReadMessageData(error)
            })
        }
    }
    
    private func didReadMessageData(_ data: Data?) {
        do {
            var message: Message? = nil
            if let messageData = data {
                message = try self.encoder.decode(data: messageData)
            }
            onRecieveMessage?(message)
        }
        catch {
            onDidFailToEncodeMessage?(error)
        }
    }
    
    private func didFailReadMessageData(_ error: Error?) {
        onDidFailToEncodeMessage?(error)
    }
}
