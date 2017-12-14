//
//  NSLayoutConstraint+DialExt.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 03/05/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

extension NSLayoutConstraint {
    
    public class func de_wrappingView(_ view: UIView,
                                      bindToTopLayoutGuide: UILayoutSupport? = nil,
                                      bindToBottomLayoutGuide: UILayoutSupport? = nil,
                                      insets: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
        
        let viewName = "view"
        let viewsInfo = [viewName: view]
        let metrics = [
            "left" : insets.left,
            "right" : insets.right,
            "top" : insets.top,
            "bottom": insets.bottom
        ]
        
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-left-[\(viewName)]-right-|", options: [], metrics: metrics, views: viewsInfo)
        
        var verticalConstraints: [NSLayoutConstraint] = []
        if let guide = bindToTopLayoutGuide {
            let constraint = NSLayoutConstraint.init(item: view, attribute: .top, relatedBy: .equal,
                                                     toItem: guide, attribute: .bottom, multiplier: 1.0,
                                                     constant: insets.top)
            verticalConstraints.append(constraint)
        }
        else {
            let constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-top-[\(viewName)]",
                metrics: metrics,
                views: viewsInfo)
            verticalConstraints.append(contentsOf: constraints)
        }
        
        if let guide = bindToBottomLayoutGuide {
            let constraint = NSLayoutConstraint.init(item: view, attribute: .bottom, relatedBy: .equal,
                                                     toItem: guide, attribute: .top, multiplier: 1.0,
                                                     constant: insets.bottom)
            verticalConstraints.append(constraint)
        }
        else {
            let constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[\(viewName)]-bottom-|",
                metrics: metrics,
                views: viewsInfo)
            verticalConstraints.append(contentsOf: constraints)
        }
        
        let constraints = horizontalConstraints + verticalConstraints
        return constraints
    }
    
    
    public struct MatchRequest: CustomStringConvertible {
        
        public struct ItemInfo: CustomStringConvertible, Equatable {
            public var item: AnyObject?
            public var attribute: NSLayoutAttribute?
            
            public init(item: AnyObject?, attribute: NSLayoutAttribute? = nil) {
                self.item = item
                self.attribute = attribute
            }
            
            public static let empty = ItemInfo.init(item: nil)
            
            public var description: String {
                let itemDescription: String
                if let item = item, let descr = item.description {
                    itemDescription = descr
                }
                else {
                    itemDescription = "nil"
                }
                
                var entries: [(String, String)] = [("item", itemDescription)]
                if let attribute = attribute {
                    entries.append(("attr", attribute.attributeDescription))
                }
                let entriesDescr: String = entries.map({ return "\($0.0) : \($0.1)" }).joined(separator: ", ")
                return "<Item: \(entriesDescr)>"
            }
            
            public static func ==(lhs: ItemInfo, rhs: ItemInfo) -> Bool {
                return lhs.item === rhs.item && lhs.attribute == rhs.attribute
            }
            
            public var hashValue: Int {
                if let item = item  {
                    return ObjectIdentifier(item).hashValue
                }
                return 0
            }
        }
        
        public var firstItem: ItemInfo
        
        public var secondItem: ItemInfo
        
        /**
         Is First Item in Match request can be second item of constaint (so request's second item should be constraint's first item)
         */
        public var areItemsMayBeRearranged: Bool = true
        
        public var relation: NSLayoutRelation?
        
        public var multiplier: CGFloat?
        
        public var constant: CGFloat?
        
        public func testConstraint(_ constraint: NSLayoutConstraint) -> Bool {
            
            var basicItemsSatisfied = self.testConstraint(constraint,
                                                          firstItem: self.firstItem,
                                                          secondItem: self.secondItem)
            if !basicItemsSatisfied && self.areItemsMayBeRearranged {
                basicItemsSatisfied = self.testConstraint(constraint,
                                                          firstItem: self.secondItem,
                                                          secondItem: self.firstItem)
            }
            
            if !basicItemsSatisfied {
                return false
            }
            
            if let relation = self.relation, constraint.relation != relation {
                return false
            }
            
            if let multiplier = self.multiplier, constraint.multiplier != multiplier {
                return false
            }
            
            if let constant = self.constant, constraint.constant != constant {
                return false
            }
            
            return true
        }
        
        private func testConstraint(_ constraint: NSLayoutConstraint, firstItem: ItemInfo, secondItem: ItemInfo) -> Bool {
            guard constraint.firstItem === firstItem.item && constraint.secondItem === secondItem.item else {
                return false
            }
            
            if let firstAttribute = firstItem.attribute, constraint.firstAttribute != firstAttribute {
                return false
            }
            if let secondAttribute = secondItem.attribute, constraint.secondAttribute != secondAttribute {
                return false
            }
            return true
        }
        
        public static let empty = MatchRequest.init(firstItem: .empty,
                                                    secondItem: .empty,
                                                    areItemsMayBeRearranged: true,
                                                    relation: nil,
                                                    multiplier: nil,
                                                    constant: nil)
        
        public static func create(_ templateModifier: ((inout MatchRequest) -> ())) -> MatchRequest {
            var request = MatchRequest.empty
            templateModifier(&request)
            return request
        }
        
        public var description: String {
            var entries: [(String, String)] = []
            entries.append(("item1", self.firstItem.description))
            entries.append(("item2", self.secondItem.description))
            entries.append(("rearrangable", self.areItemsMayBeRearranged.description))
            if let relation = self.relation {
                entries.append(("relation", relation.rawValue.description))
            }
            if let multiplier = self.multiplier {
                entries.append(("multiplier", multiplier.description))
            }
            if let constant = self.constant {
                entries.append(("constant", constant.description))
            }
            let descr = entries.map({"\($0.0): \($0.1)"}).joined(separator: ", ")
            return "<MatchRequest, \(descr)>"
        }
        
    }
    
}

public extension NSLayoutAttribute {
    var attributeDescription: String {
        switch self {
        case .bottom: return "bottom"
        case .bottomMargin: return "bottomMargin"
        case .centerX: return "centerX"
        case .centerXWithinMargins: return "centerXWithinMargins"
        case .centerY: return "centerY"
        case .centerYWithinMargins: return "centerYWithinMargins"
        case .firstBaseline: return "firstBaseline"
        case .height: return "height"
        case .lastBaseline: return "lastBaseline"
        case .leading: return "leading"
        case .leadingMargin: return "leadingMargin"
        case .left: return "left"
        case .leftMargin: return "leftMargin"
        case .notAnAttribute: return "notAnAttribute"
        case .right: return "right"
        case .rightMargin: return "rightMargin"
        case .top: return "top"
        case .topMargin: return "topMargin"
        case .trailing: return "trailing"
        case .trailingMargin: return "trailingMargin"
        case .width: return "width"
        default: return "unknown(\(self.rawValue)"
        }
    }
}

public extension Array where Element == NSLayoutConstraint {
    public func activate() {
        NSLayoutConstraint.activate(self)
    }
}
