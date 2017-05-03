//
//  DEGroupContainerItemBindedRepresenter.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 11/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

/**
 * Defines changing representer's current representatino on storing.
 */
public enum DEGroupContainerItemBindedRepresenterStorePolicy: Int {
    
    /// Representation-to-store becomes current representation immediately
    case optimistic
    
    /// Representation-to-store becomes current only after successfully saving
    case onSuccessOnly
}

/**
 * Describes why representer updates representation
 */
public enum DEGroupContainerItemBindedRepresenterUpdateReason {
    
    /// Representer finish to loading representation
    case firstLoad
    
    /// Representer detects binded file update
    case update
    
    /// Storing representation successfully finished
    case storeSuccess
    
    /// Storing representation fails, so backup representation being set. Optimistic policy only.
    case storeFailure
}


/**
 * Synchronizes file's content with representation.
 * Can store representation
 */
public class DEGroupContainerItemBindedRepresenter<Representation> {
    
    public typealias StorePolicy = DEGroupContainerItemBindedRepresenterStorePolicy
    
    public typealias UpdateReason = DEGroupContainerItemBindedRepresenterUpdateReason
    
    private typealias RepresentationState = ThreadSafeRepresentationState<Representation>
    
    private let representer: DEGroupContainerItemRepresenter<Representation>
    
    /// Settings this variable is thread-unsafe. Set it before start or change it after start only on target queue.
    public var onDidChangeRepresentation:((Representation, UpdateReason) -> ())? = nil
    
    /// Settings this variable is thread-unsafe. Set it before start or change it after start only on target queue.
    public var onFailToSyncRepresentation:((Error?) -> ())? = nil
    
    public private(set) var isBinded: Bool = false
    
    public let storePolicy: StorePolicy
    
    public var isStoreInProgress: Bool {
        return representationState.hasBackupRepresentation
    }
    
    /// Settings this variable is thread-unsafe. Set it before you bind representer, otherwise fatal error occures.
    public var targetQueue: DispatchQueue {
        
        set {
            guard !self.isBinded else {
                fatalError("Trying to change target queue after binding")
            }
            
            self.representer.targetQueue = newValue
        }
        
        get {
            return self.representer.targetQueue
        }
    }
    
    /// Do not set representation if store in progress. Set will be ignored.
    public var representation: Representation! {
        set {
            guard !self.isStoreInProgress else {
                return
            }
            
            switch self.storePolicy {
                
            case .optimistic:
                self.representationState.setNewRepresentation(newValue, moveCurrentToBackup: true)
                
            case .onSuccessOnly:
                self.representationState.setBackupRepresentation(newValue)
            }
            
            self.storeRepresentation(newValue)
        }
        
        get {
            return self.representationState.currentRepresentation
        }
    }
    
    private let representationState = RepresentationState.init()
    
    convenience public init(item: DEGroupContainerItem,
                            encoder: DEGroupContainerItemDataEncoder<Representation>,
                            storePolicy: DEGroupContainerItemBindedRepresenterStorePolicy = .onSuccessOnly) {
        let representer = DEGroupContainerItemRepresenter.init(item: item, encoder: encoder)
        self.init(unbindableRepresenter: representer, storePolicy: storePolicy)
    }
    
    public init(unbindableRepresenter: DEGroupContainerItemRepresenter<Representation>,
                storePolicy: DEGroupContainerItemBindedRepresenterStorePolicy = .onSuccessOnly) {
        self.representer = unbindableRepresenter
        self.storePolicy = storePolicy
    }
    
    public func bind() {
        guard !self.isBinded else {
            return
        }
        
        self.redoRepresent(dueUpdate: false)
    }
    
    private func redoRepresent(dueUpdate: Bool) {
        self.representer.represent { [weak self] (result) in
            withExtendedLifetime(self, {
                switch result {
                case let .success(representation): self?.resetRepresentation(representation, dueUpdate: dueUpdate)
                case let .failure(error): self?.handleFirstLoadingFailure(error: error, isUpdate: dueUpdate)
                }
            })
        }
    }
    
    private func handleFirstLoadingFailure(error: Error?, isUpdate: Bool) {
        print("Fail to sync representation: \(String(describing: error))")
        self.signalRepresentationUpdateFailed(error: error, isUpdate: isUpdate)
    }
    
    private func storeRepresentation(_ rep: Representation) {
        self.representer.store(representation: rep) { [weak self] (result) in
            withExtendedLifetime(self, {
                switch result {
                case .success(_): self?.handleRepresentationStoreFinished(success: true)
                case .failure(_): self?.handleRepresentationStoreFinished(success: false)
                }
            })
        }
    }
    
    private func handleRepresentationStoreFinished(success: Bool) {
        if (success && self.storePolicy == .onSuccessOnly) {
            self.representationState.moveBackupRepresentationToCurrent()
            self.signalRepresentationUpdate(reason: .storeSuccess)
        }
        
        if (!success && self.storePolicy == .optimistic) {
            self.representationState.moveBackupRepresentationToCurrent()
            self.signalRepresentationUpdate(reason: .storeFailure)
        }
    }
    
    private func resetRepresentation(_ representation: Representation, dueUpdate: Bool) {
        self.representationState.setNewRepresentation(representation, moveCurrentToBackup: false)
        
        let reason: UpdateReason = dueUpdate ? UpdateReason.update : UpdateReason.firstLoad
        self.signalRepresentationUpdate(reason: reason)
    }
    
    private func signalRepresentationUpdateFailed(error: Error?, isUpdate: Bool) {
        self.targetQueue.async {
            self.onFailToSyncRepresentation?(error)
        }
    }
    
    private func signalRepresentationUpdate(reason: UpdateReason) {
        if let representation = self.representationState.currentRepresentation {
            self.targetQueue.async {
                self.onDidChangeRepresentation?(representation, reason)
            }
        }
    }
    
    private func handleChanges() {
        redoRepresent(dueUpdate: true)
    }
    
}
