//
//  DELogService.swift
//  DialogSDK
//
//  Created by Aleksei Gordeev on 23/06/2017.
//  Copyright © 2017 Dialog LLC. All rights reserved.
//

import Foundation
import os

public protocol DELogService {
    func log(_ message: String,
             subsystem: DELogger.Subsystem,
             tag: String,
             level: DELogger.Level,
             info: DELogger.Info?,
             logger: DELogger)
}

extension DELogService {
    func slog(_ message: StaticString, subsystem: DELogger.Subsystem, tag: String, level: DELogger.Level, logger: DELogger) {
        self.log(message.description, subsystem: subsystem, tag: tag, level: level, info: nil, logger: logger)
    }
}

public class DEDebugConsoleLogService: DELogService {
    
    public func log(_ message: String,
                    subsystem: DELogger.Subsystem,
                    tag: String,
                    level: DELogger.Level,
                    info: DELogger.Info?,
                    logger: DELogger) {
        var result = "\(subsystem) [\(tag)]"
        if level != .default {
            result.append(" \(level)")
        }
        result.append(message)
        print("[\(subsystem): \(tag) <\(level)>]: \(message)")
    }
    
}

@available(iOS 10, *) public class DEiOSLogService: DELogService {
    
    public func log(_ message: String,
                    subsystem: DELogger.Subsystem,
                    tag: String,
                    level: DELogger.Level,
                    info: DELogger.Info?,
                    logger: DELogger) {
        // do nothing (OS does not support sensitive data logging)
    }
    
    /// Override for put in console
    public func slog(_ message: StaticString, subsystem: DELogger.Subsystem, tag: String, level: DELogger.Level, logger: DELogger) {
        let type = level.osLogType
        let log = OSLog.init(subsystem: subsystem.rawValue, category: tag)
        guard log.isEnabled(type: type) else {
            return
        }
        
        os_log(message, log: log, type: type)
    }
}

@available(iOS 10, *) fileprivate extension DELogger.Level {
    var osLogType: OSLogType {
        switch self {
        case .debug: return OSLogType.debug
        case .default: return OSLogType.default
        case .error: return OSLogType.error
        case .fault: return OSLogType.fault
        case .info: return OSLogType.info
        case .private: return OSLogType.debug
        case .warning: return OSLogType.info
        }
    }
}
