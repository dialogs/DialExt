//
//  ThreadSafeRepresentationState.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 12/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

/**
 * Storing representations. Thread-safe.
 */
internal class ThreadSafeRepresentationState<Representation> {
    
    public var currentRepresentation: Representation? {
        var representation: Representation? = nil
        perform {
            representation = self._lastSetRepresentation
        }
        return representation
    }
    
    public var backupRepresentation: Representation? {
        var representation: Representation? = nil
        perform {
            representation = self._backupRepresentation
        }
        return representation
    }
    
    public var hasBackupRepresentation: Bool {
        return self.backupRepresentation != nil
    }
    
    private var _lastSetRepresentation: Representation? = nil
    
    private var _backupRepresentation: Representation? = nil
    
    private let mutex = PThreadMutex.init()
    
    func perform(_ block:(()->())) {
        mutex.sync(execute:{
            block()
        })
    }
    
    func setNewRepresentation(_ representation: Representation, moveCurrentToBackup: Bool = false) {
        perform {
            if moveCurrentToBackup {
                self._backupRepresentation = self._lastSetRepresentation
            }
            self._lastSetRepresentation = representation
        }
    }
    
    func setBackupRepresentation(_ representation: Representation?) {
        perform {
            self._backupRepresentation = representation
        }
    }
    
    func moveBackupRepresentationToCurrent(newBackupRepresentation: Representation? = nil) {
        perform {
            self._lastSetRepresentation = self._backupRepresentation
            self._backupRepresentation = newBackupRepresentation
        }
    }
}
