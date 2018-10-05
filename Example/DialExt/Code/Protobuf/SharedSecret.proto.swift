/// Generated by the Protocol Buffers 3.6.1 compiler.  DO NOT EDIT!
/// Protobuf-swift version: 4.0.0
/// Source file "shared_secret.proto"
/// Syntax "Proto3"

import Foundation
import ProtocolBuffers


public struct SharedSecretRoot {
    public static let `default` = SharedSecretRoot()
    public var extensionRegistry:ExtensionRegistry

    init() {
        extensionRegistry = ExtensionRegistry()
        registerAllExtensions(registry: extensionRegistry)
    }
    public func registerAllExtensions(registry: ExtensionRegistry) {
    }
}

final public class SharedSecret : GeneratedMessage {
    public typealias BuilderType = SharedSecret.Builder

    public static func == (lhs: SharedSecret, rhs: SharedSecret) -> Bool {
        if lhs === rhs {
            return true
        }
        var fieldCheck:Bool = (lhs.hashValue == rhs.hashValue)
        fieldCheck = fieldCheck && (lhs.hasRx == rhs.hasRx) && (!lhs.hasRx || lhs.rx == rhs.rx)
        fieldCheck = fieldCheck && (lhs.hasTx == rhs.hasTx) && (!lhs.hasTx || lhs.tx == rhs.tx)
        fieldCheck = (fieldCheck && (lhs.unknownFields == rhs.unknownFields))
        return fieldCheck
    }

    public fileprivate(set) var rx:Data! = nil
    public fileprivate(set) var hasRx:Bool = false

    public fileprivate(set) var tx:Data! = nil
    public fileprivate(set) var hasTx:Bool = false

    required public init() {
        super.init()
    }
    override public func isInitialized() throws {
    }
    override public func writeTo(codedOutputStream: CodedOutputStream) throws {
        if hasRx {
            try codedOutputStream.writeData(fieldNumber: 1, value:rx)
        }
        if hasTx {
            try codedOutputStream.writeData(fieldNumber: 2, value:tx)
        }
        try unknownFields.writeTo(codedOutputStream: codedOutputStream)
    }
    override public func serializedSize() -> Int32 {
        var serialize_size:Int32 = memoizedSerializedSize
        if serialize_size != -1 {
         return serialize_size
        }

        serialize_size = 0
        if hasRx {
            serialize_size += rx.computeDataSize(fieldNumber: 1)
        }
        if hasTx {
            serialize_size += tx.computeDataSize(fieldNumber: 2)
        }
        serialize_size += unknownFields.serializedSize()
        memoizedSerializedSize = serialize_size
        return serialize_size
    }
    public class func getBuilder() -> SharedSecret.Builder {
        return SharedSecret.classBuilder() as! SharedSecret.Builder
    }
    public func getBuilder() -> SharedSecret.Builder {
        return classBuilder() as! SharedSecret.Builder
    }
    override public class func classBuilder() -> ProtocolBuffersMessageBuilder {
        return SharedSecret.Builder()
    }
    override public func classBuilder() -> ProtocolBuffersMessageBuilder {
        return SharedSecret.Builder()
    }
    public func toBuilder() throws -> SharedSecret.Builder {
        return try SharedSecret.builderWithPrototype(prototype:self)
    }
    public class func builderWithPrototype(prototype:SharedSecret) throws -> SharedSecret.Builder {
        return try SharedSecret.Builder().mergeFrom(other:prototype)
    }
    override public func encode() throws -> Dictionary<String,Any> {
        try isInitialized()
        var jsonMap:Dictionary<String,Any> = Dictionary<String,Any>()
        if hasRx {
            jsonMap["rx"] = rx.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
        }
        if hasTx {
            jsonMap["tx"] = tx.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
        }
        return jsonMap
    }
    override class public func decode(jsonMap:Dictionary<String,Any>) throws -> SharedSecret {
        return try SharedSecret.Builder.decodeToBuilder(jsonMap:jsonMap).build()
    }
    override class public func fromJSON(data:Data, options: JSONSerialization.ReadingOptions = []) throws -> SharedSecret {
        return try SharedSecret.Builder.fromJSONToBuilder(data:data, options:options).build()
    }
    override public func getDescription(indent:String) throws -> String {
        var output = ""
        if hasRx {
            output += "\(indent) rx: \(String(describing: rx)) \n"
        }
        if hasTx {
            output += "\(indent) tx: \(String(describing: tx)) \n"
        }
        output += unknownFields.getDescription(indent: indent)
        return output
    }
    override public var hashValue:Int {
        get {
            var hashCode:Int = 7
            if hasRx {
                hashCode = (hashCode &* 31) &+ rx.hashValue
            }
            if hasTx {
                hashCode = (hashCode &* 31) &+ tx.hashValue
            }
            hashCode = (hashCode &* 31) &+  unknownFields.hashValue
            return hashCode
        }
    }


    //Meta information declaration start

    override public class func className() -> String {
        return "SharedSecret"
    }
    override public func className() -> String {
        return "SharedSecret"
    }
    //Meta information declaration end

    final public class Builder : GeneratedMessageBuilder {
        fileprivate var builderResult:SharedSecret = SharedSecret()
        public func getMessage() -> SharedSecret {
            return builderResult
        }

        required override public init () {
            super.init()
        }
        public var rx:Data {
            get {
                return builderResult.rx
            }
            set (value) {
                builderResult.hasRx = true
                builderResult.rx = value
            }
        }
        public var hasRx:Bool {
            get {
                return builderResult.hasRx
            }
        }
        @discardableResult
        public func setRx(_ value:Data) -> SharedSecret.Builder {
            self.rx = value
            return self
        }
        @discardableResult
        public func clearRx() -> SharedSecret.Builder{
            builderResult.hasRx = false
            builderResult.rx = nil
            return self
        }
        public var tx:Data {
            get {
                return builderResult.tx
            }
            set (value) {
                builderResult.hasTx = true
                builderResult.tx = value
            }
        }
        public var hasTx:Bool {
            get {
                return builderResult.hasTx
            }
        }
        @discardableResult
        public func setTx(_ value:Data) -> SharedSecret.Builder {
            self.tx = value
            return self
        }
        @discardableResult
        public func clearTx() -> SharedSecret.Builder{
            builderResult.hasTx = false
            builderResult.tx = nil
            return self
        }
        override public var internalGetResult:GeneratedMessage {
            get {
                return builderResult
            }
        }
        @discardableResult
        override public func clear() -> SharedSecret.Builder {
            builderResult = SharedSecret()
            return self
        }
        override public func clone() throws -> SharedSecret.Builder {
            return try SharedSecret.builderWithPrototype(prototype:builderResult)
        }
        override public func build() throws -> SharedSecret {
            try checkInitialized()
            return buildPartial()
        }
        public func buildPartial() -> SharedSecret {
            let returnMe:SharedSecret = builderResult
            return returnMe
        }
        @discardableResult
        public func mergeFrom(other:SharedSecret) throws -> SharedSecret.Builder {
            if other == SharedSecret() {
                return self
            }
            if other.hasRx {
                rx = other.rx
            }
            if other.hasTx {
                tx = other.tx
            }
            try merge(unknownField: other.unknownFields)
            return self
        }
        @discardableResult
        override public func mergeFrom(codedInputStream: CodedInputStream) throws -> SharedSecret.Builder {
            return try mergeFrom(codedInputStream: codedInputStream, extensionRegistry:ExtensionRegistry())
        }
        @discardableResult
        override public func mergeFrom(codedInputStream: CodedInputStream, extensionRegistry:ExtensionRegistry) throws -> SharedSecret.Builder {
            let unknownFieldsBuilder:UnknownFieldSet.Builder = try UnknownFieldSet.builderWithUnknownFields(copyFrom:self.unknownFields)
            while (true) {
                let protobufTag = try codedInputStream.readTag()
                switch protobufTag {
                case 0: 
                    self.unknownFields = try unknownFieldsBuilder.build()
                    return self

                case 10:
                    rx = try codedInputStream.readData()

                case 18:
                    tx = try codedInputStream.readData()

                default:
                    if (!(try parse(codedInputStream:codedInputStream, unknownFields:unknownFieldsBuilder, extensionRegistry:extensionRegistry, tag:protobufTag))) {
                        unknownFields = try unknownFieldsBuilder.build()
                        return self
                    }
                }
            }
        }
        class override public func decodeToBuilder(jsonMap:Dictionary<String,Any>) throws -> SharedSecret.Builder {
            let resultDecodedBuilder = SharedSecret.Builder()
            if let jsonValueRx = jsonMap["rx"] as? String {
                resultDecodedBuilder.rx = Data(base64Encoded:jsonValueRx, options: Data.Base64DecodingOptions(rawValue:0))!
            }
            if let jsonValueTx = jsonMap["tx"] as? String {
                resultDecodedBuilder.tx = Data(base64Encoded:jsonValueTx, options: Data.Base64DecodingOptions(rawValue:0))!
            }
            return resultDecodedBuilder
        }
        override class public func fromJSONToBuilder(data:Data, options: JSONSerialization.ReadingOptions = []) throws -> SharedSecret.Builder {
            let jsonData = try JSONSerialization.jsonObject(with:data, options: options)
            guard let jsDataCast = jsonData as? Dictionary<String,Any> else {
              throw ProtocolBuffersError.invalidProtocolBuffer("Invalid JSON data")
            }
            return try SharedSecret.Builder.decodeToBuilder(jsonMap:jsDataCast)
        }
    }

}

extension SharedSecret: GeneratedMessageProtocol {
    public class func parseArrayDelimitedFrom(inputStream: InputStream) throws -> Array<SharedSecret> {
        var mergedArray = Array<SharedSecret>()
        while let value = try parseDelimitedFrom(inputStream: inputStream) {
          mergedArray.append(value)
        }
        return mergedArray
    }
    public class func parseDelimitedFrom(inputStream: InputStream) throws -> SharedSecret? {
        return try SharedSecret.Builder().mergeDelimitedFrom(inputStream: inputStream)?.build()
    }
    public class func parseFrom(data: Data) throws -> SharedSecret {
        return try SharedSecret.Builder().mergeFrom(data: data, extensionRegistry:SharedSecretRoot.default.extensionRegistry).build()
    }
    public class func parseFrom(data: Data, extensionRegistry:ExtensionRegistry) throws -> SharedSecret {
        return try SharedSecret.Builder().mergeFrom(data: data, extensionRegistry:extensionRegistry).build()
    }
    public class func parseFrom(inputStream: InputStream) throws -> SharedSecret {
        return try SharedSecret.Builder().mergeFrom(inputStream: inputStream).build()
    }
    public class func parseFrom(inputStream: InputStream, extensionRegistry:ExtensionRegistry) throws -> SharedSecret {
        return try SharedSecret.Builder().mergeFrom(inputStream: inputStream, extensionRegistry:extensionRegistry).build()
    }
    public class func parseFrom(codedInputStream: CodedInputStream) throws -> SharedSecret {
        return try SharedSecret.Builder().mergeFrom(codedInputStream: codedInputStream).build()
    }
    public class func parseFrom(codedInputStream: CodedInputStream, extensionRegistry:ExtensionRegistry) throws -> SharedSecret {
        return try SharedSecret.Builder().mergeFrom(codedInputStream: codedInputStream, extensionRegistry:extensionRegistry).build()
    }
    public subscript(key: String) -> Any? {
        switch key {
        case "rx": return self.rx
        case "tx": return self.tx
        default: return nil
        }
    }
}
extension SharedSecret.Builder: GeneratedMessageBuilderProtocol {
    public typealias GeneratedMessageType = SharedSecret
    public subscript(key: String) -> Any? {
        get { 
            switch key {
            case "rx": return self.rx
            case "tx": return self.tx
            default: return nil
            }
        }
        set (newSubscriptValue) { 
            switch key {
            case "rx":
                guard let newSubscriptValue = newSubscriptValue as? Data else {
                    return
                }
                self.rx = newSubscriptValue
            case "tx":
                guard let newSubscriptValue = newSubscriptValue as? Data else {
                    return
                }
                self.tx = newSubscriptValue
            default: return
            }
        }
    }
}

// @@protoc_insertion_point(global_scope)
