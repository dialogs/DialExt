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


public class DEGroupContainerItemDataEncoder<Representation> {
    
    func decode(data: Data) throws -> Representation {
        fatalError("Should be implemented in subclass")
    }
    
    func encode(representation: Representation) throws -> Data {
        fatalError("Should be implemented in subclass")
    }
    
}

public class DEGroupContainerItemRepresenter<Representation> {
    
    public typealias DecodeResult = DEGroupContainerItemRepresenterResult<Representation>
    
    public typealias DecodeHandler = ((_ result: DecodeResult, _ isUpdate: Bool) -> ())
    
    
    public typealias EncodeResult = DEGroupContainerItemRepresenterResult<Data>
    
    public typealias EncodeHandler =  ((_ result: EncodeResult) -> ())
    
    
    public let item: DEGroupContainerItem
    
    public let encoder: DEGroupContainerItemDataEncoder<Representation>
    
    public var targetQueue: DispatchQueue = DispatchQueue.main
    
    public init(item: DEGroupContainerItem, encoder: DEGroupContainerItemDataEncoder<Representation>) {
        self.item = item
        self.encoder = encoder
        
        self.item.onDidChange = { [weak self] in
            withExtendedLifetime(self, {
                self?.handleChanges()
            })
        }
    }

    public func startObserving(handler: @escaping DecodeHandler) {
        self.permanentHandler = handler
        self.redoRepresent(dueUpdate: false)
    }
    
    /// Instance is guaranteed to live untill completion executed and handler performed.
    /// 'isUpdate' in handler is always false.
    public func represent(handler: @escaping DecodeHandler ) {
        self.item.readData({ (data) in
            withExtendedLifetime(self, {
                let result = self.buildDecodeResult(data: data)
                self.performOnTargetQueue {
                    handler(result, false)
                }
            })
        }) { (error) in
            withExtendedLifetime(self, {
                let result = DecodeResult.failure(error)
                self.performOnTargetQueue {
                    handler(result, false)
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
    
    private var permanentHandler: DecodeHandler? = nil
    
    private func redoRepresent(dueUpdate: Bool) {
        self.represent { (result, _) in
            self.performPermanentHandler(result: result, isUpdate: dueUpdate)
        }
    }
    
    private func performPermanentHandler(result: DecodeResult, isUpdate: Bool) {
        self.permanentHandler?(result, isUpdate)
    }
    
    private func handleChanges() {
        redoRepresent(dueUpdate: true)
    }
    
}
