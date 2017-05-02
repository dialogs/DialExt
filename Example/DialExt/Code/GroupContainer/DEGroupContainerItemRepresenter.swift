//
//  DEGroupContainerItemRepresenter.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 05/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation



public enum DEGroupContainerItemRepresenterResult<Representation> {
    case success(Representation)
    case failure(Error?)
}


open class DEGroupContainerItemDataEncoder<Representation> {
    
    open func decode(data: Data) throws -> Representation {
        fatalError("Should be implemented in subclass")
    }
    
    open func encode(representation: Representation) throws -> Data {
        fatalError("Should be implemented in subclass")
    }
    
    public init() {
        
    }
    
}

/// Binds to container file and autoupdate it's representation.
public class DEGroupContainerItemRepresenter<Representation> {
    
    public typealias DecodeResult = DEGroupContainerItemRepresenterResult<Representation>
    
    public typealias DecodeHandler = ((_ result: DecodeResult) -> ())
    
    
    public typealias EncodeResult = DEGroupContainerItemRepresenterResult<Data>
    
    public typealias EncodeHandler =  ((_ result: EncodeResult) -> ())
    
    
    internal let item: DEGroupContainerItem
    
    public let encoder: DEGroupContainerItemDataEncoder<Representation>
    
    public var targetQueue: DispatchQueue = DispatchQueue.main
    
    public init(item: DEGroupContainerItem, encoder: DEGroupContainerItemDataEncoder<Representation>) {
        self.item = item
        self.encoder = encoder
    }

    /// Instance is guaranteed to live untill completion executed and handler performed.
    /// 'isUpdate' in handler is always false.
    public func represent(handler: @escaping DecodeHandler ) {
        self.item.readData({ (data) in
            withExtendedLifetime(self, {
                let result = self.buildDecodeResult(data: data)
                self.performOnTargetQueue {
                    handler(result)
                }
            })
        }) { (error) in
            withExtendedLifetime(self, {
                let result = DecodeResult.failure(error)
                self.performOnTargetQueue {
                    handler(result)
                }
            })
        }
    }
    
    public func store(representation: Representation, handler: EncodeHandler? = nil) {
        DispatchQueue.global(qos: .utility).async {
            withExtendedLifetime(self, {
                let data: Data
                do {
                    data = try self.encoder.encode(representation: representation)
                }
                catch {
                    if let resultHandler = handler {
                        let result = EncodeResult.failure(error)
                        self.performOnTargetQueue {
                            resultHandler(result)
                        }
                    }
                    return
                }
                
                self.item.writeData(data, onFinish: { (success, error) in
                    withExtendedLifetime(self, {
                        if let resultHandler = handler {
                            let result: EncodeResult
                            if success {
                                result = EncodeResult.success(data)
                            }
                            else {
                                result = EncodeResult.failure(error)
                            }
                            
                            self.performOnTargetQueue {
                                resultHandler(result)
                            }
                        }
                    })
                })
            })
        }
    }
    
    private func performOnTargetQueue(code: @escaping (() -> ())) {
        self.targetQueue.async(execute: code)
    }
    
    private func buildDecodeResult(data: Data?) -> DecodeResult {
        let result: DecodeResult
        if let sourceData = data {
            do {
                let rep = try self.encoder.decode(data: sourceData)
                result = DecodeResult.success(rep)
            }
            catch {
                result = DecodeResult.failure(error)
            }
        }
        else {
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotParseResponse, userInfo: nil)
            result = DecodeResult.failure(error)
        }
        
        return result
    }
    
}
