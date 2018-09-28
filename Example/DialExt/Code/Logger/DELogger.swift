//
//  DELogger.swift
//  DialogSDK
//
//  Created by Aleksei Gordeev on 23/06/2017.
//  Copyright © 2017 Dialog LLC. All rights reserved.
//

import Foundation
import os


public struct DELogPosition {
    public let file: StaticString
    public let function: StaticString
    public let line: UInt
}

public func DEErrorLog(_ message: String = "",
                       _ error: Error,
                       isFatal: Bool = false,
                       file: StaticString = #file,
                       function: StaticString = #function,
                       line: UInt = #line) {
    let errorString = String(describing: error) + " - " + error.localizedDescription
    let result = message + " " + errorString
    DEErrorLog(result, file: file, function: function, line: line)
}

public func DELog(_ message: String = "",
                  subsystem: DELogger.Subsystem = .sdk,
                  tag: String = "",
                  level: DELogger.Level = .default,
                  info: DELoggerInfo? = nil,
                  logger: DELogger = DELogger.shared,
                  file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    var info: DELoggerInfo = info ?? DELoggerInfo()
    info[.position] = DELogPosition(file: file, function: function, line: line)
    logger.log(message, subsystem: subsystem, tag: tag, level: level, info: info)
}

public func DESErrorLog(_ message: StaticString, isFatal: Bool = false,
                        subsystem: DELogger.Subsystem = .sdk,
                        tag: String = "",
                        info: DELoggerInfo? = nil,
                        logger: DELogger = DELogger.shared,
                        file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    DESLog(message,
           tag: tag,
           level: isFatal ? DELogger.Level.fault : DELogger.Level.error,
           logger: logger,
           file: file,
           function: function,
           line: line)
}

public func DESWarnLog(_ message: StaticString,
                      subsystem: DELogger.Subsystem = .sdk,
                      tag: String = "",
                      info: DELoggerInfo? = nil,
                      logger: DELogger = DELogger.shared,
                      file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    DESLog(message,
          tag: tag,
          level: DELogger.Level.warning,
          logger: logger,
          file: file,
          function: function,
          line: line)
}

public func DEWarnLog(_ message: String,
                       subsystem: DELogger.Subsystem = .sdk,
                       tag: String = "",
                       info: DELoggerInfo? = nil,
                       logger: DELogger = DELogger.shared,
                       file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    DELog(message,
          tag: tag,
          level: DELogger.Level.warning,
          info: info,
          logger: logger,
          file: file,
          function: function,
          line: line)
}

public func DEErrorLog(_ message: String,
                       isFatal: Bool = false,
                       subsystem: DELogger.Subsystem = .sdk,
                       tag: String = "",
                       info: DELoggerInfo? = nil,
                       logger: DELogger = DELogger.shared,
                       file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    DELog(message,
          tag: tag,
          level: isFatal ? DELogger.Level.fault : DELogger.Level.error,
          info: info,
          logger: logger,
          file: file,
          function: function,
          line: line)
}

public func DESLog(_ message: StaticString,
                   subsystem: DELogger.Subsystem = .sdk,
                   tag: String = "",
                   level: DELogger.Level = .default,
                   logger: DELogger = DELogger.shared,
                   file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    var info = DELoggerInfo()
    info[.position] = DELogPosition(file: file, function: function, line: line)
    logger.slog(message, subsystem: subsystem, tag: tag, level: level, info: info)
}

public final class DELogger: NSObject {
    
    public static let shared = DELogger.init()
    
    deinit {
        self.services = []
    }
    
    public var services: [DELogService] {
        set {
            self.threadSafer.sync(execute: {
                self.threadSafeServices = newValue
            })
        }
        get {
            var services: [DELogService] = []
            self.threadSafer.sync {
                services = self.threadSafeServices
            }
            return services
        }
    }
    
    private let threadSafer = PThreadMutex.init()
    private var threadSafeServices:[DELogService] = []
    
    override public init() {
        var services: [DELogService] = [DEDebugConsoleLogService.init()]
        if #available(iOS 10, *) {
            services.append(DEiOSLogService.init())
        }
        threadSafeServices = services
        
        super.init()
    }
    
    public func log(_ message: String, subsystem: Subsystem = .sdk, tag: String, level: Level = .default, info: Info? = nil) {
        self.services.forEach({
            $0.log(message, subsystem: subsystem, tag: tag, level: level, info: info, logger: self)
        })
    }
    
    public func slog(_ message: StaticString, subsystem: Subsystem = .sdk, tag: String, level: Level = .default, info: Info? = nil) {
        self.services.forEach({$0.slog(message, subsystem: subsystem, tag: tag, level: level, logger: self)})
    }
    
    public enum Level: CustomStringConvertible {
        case `default`
        case info
        case debug
        case error
        case fault
        case warning
        
        /// Log service should swallow log with level when app is not in debug, because logged data may be sensitive
        case `private`
        
        public var description: String {
            switch self {
            case .default: return "default"
            case .info: return "info"
            case .debug: return "debug"
            case .error: return "ERROR"
            case .fault: return "FAULT"
            case .warning: return "warning"
                
            case .private: return "PRIVATE"
            }
        }
    }
    
    
    
    public struct Subsystem: RawRepresentable {
        
        public typealias RawValue = String
        
        public let rawValue: String
        
        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
        
        public init(_ rawValue: RawValue) {
            self.rawValue = rawValue
        }
    }
}

public extension DELogger.Subsystem {
    
    public static let sdk = DELogger.Subsystem.init("DialogSDK[iOS]")
    
}


