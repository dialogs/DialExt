//
//  DEGroupContainerItemBindedRepresenterQueuer.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 12/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

/**
 * Queuer is repsonsible for put representations into item-binded representer.
 * You can pass not only prepared representation, but representer-blocks, which are called when representer become free for writing.
 * Moreover, while representer is busy, you can put representatation items any time and only last one will be stored.
 * Also, if any representer block being put into queuer while previous representer-block is preparing representation -
 *  the representation of previous repreosenter-block will not be stored to avoid of unnecessary file writing.
 *
 * Scheme is next.
 * Condition: Queuer is preparing rep 1, while developer pushes Rep2, then Rep3 and then Rep4 (no matter, whether it prepared representations or preparator-blocks)
 *
 *                              [Rep1 x]
 *  [Rep4 ✓]-[Rep3 x]-[Rep2 x] → [ QUEUER ] → [Representer]
 *
 * Rep1 will not be store, because when it preparing finished - there will be another RepN, that should be prepared and stored.
 * While Rep1 is preparing – Rep2 will be replaced by Rep3 and Rep3 will be replaced by Rep4
 * So there is only one rep will be stored – the Rep4.
 *
 * Not being tested.
 */
public class DEGroupContainerItemBindedRepresenterQueuer<Representation> {
    
    public typealias RepresentationPreparator = (() -> (Representation?))
    
    public typealias Representer = DEGroupContainerItemBindedRepresenter<Representation>
    
    public func put(representation: Representation) {
        put(item: Item.init(content: .prepared(representation)))
    }
    
    public func put(preparation: @escaping RepresentationPreparator) {
        put(item: Item.init(content: .preparator(preparation)))
    }
    
    public func tryPutNextItem() {
        if let item = self.nextItem {
            processItem(item: item)
        }
    }
    
    public var name: String? = nil
    
    private typealias Item = DEGroupContainerItemBindedRepresenterQueueItem<Representation>
    
    private var nextItem: Item? {
        set {
            _nextItemMutex.sync(execute: {
                self._nextItem = newValue
            })
        }
        
        get {
            var item: Item? = nil
            _nextItemMutex.sync(execute: {
                item = self._nextItem
            })
            return item
        }
    }
    
    private var _nextItemMutex = PThreadMutex.init()
    private var _nextItem: Item? = nil
    
    private let queue = DispatchQueue.global(qos: .background)
    
    private let representer: Representer
    
    init(representer: Representer) {
        self.representer = representer
    }
    
    private func put(item: Item) {
        self.nextItem = item
        
        if !representer.isStoreInProgress {
            processItem(item: item)
        }
    }
    
    private func processItem(item: Item) {
        queue.async {
            if let representation = item.representation, self.nextItem == item {
                self.nextItem = nil
                self.representer.representation = representation
            }
        }
    }
    
}

fileprivate class DEGroupContainerItemBindedRepresenterQueueItem<Representation>: Equatable {
    
    typealias Content = DEGroupContainerItemBindedRepresenterQueueItemContent<Representation>
    
    let content: Content
    
    let uuid = UUID.init()
    
    public static func ==(lhs: DEGroupContainerItemBindedRepresenterQueueItem<Representation>,
                          rhs: DEGroupContainerItemBindedRepresenterQueueItem<Representation>) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    var representation: Representation? {
        switch self.content {
        case let .prepared(representation): return representation
        case let .preparator(preparator): return preparator()
        }
    }
    
    init(content: Content) {
        self.content = content
    }
}

fileprivate enum DEGroupContainerItemBindedRepresenterQueueItemContent<Representation> {
    case prepared(Representation?)
    case preparator(DEGroupContainerItemBindedRepresenterQueuer<Representation>.RepresentationPreparator)
}
