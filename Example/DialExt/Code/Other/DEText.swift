//
//  DEText.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 21/10/2017.
//  Copyright © 2017 Dialog LLC. All rights reserved.
//

import Foundation
import UIKit

public enum DEText: Hashable, CustomStringConvertible {
    
    case string(String)
    case attributedString(NSAttributedString)
    
    public typealias Attributes = [String : Any]

    public var description: String {
        switch self {
        case .string(let string):
            return string.description
        case .attributedString(let string):
            return string.description
        }
    }

    public var isAttributed: Bool {
        switch self {
        case .attributedString(_): return true
        default: return false
        }
    }

    public var toString: String {
        switch self {
        case .string(let string): return string
        case .attributedString(let attributedString): return attributedString.string
        }
    }

    public func toAttributedString(attributes: @autoclosure ()->(Attributes)) -> NSAttributedString {
        switch self {
        case .string(let string):
            let attrs = attributes()
            var newAttributes: [NSAttributedStringKey : Any] = [:]
            for entry in attrs {
                newAttributes[NSAttributedStringKey.init(entry.key)] = entry.value
            }
            return NSAttributedString.init(string: string, attributes: newAttributes)
        case .attributedString(let attributedString): return attributedString
        }
    }

    public func isEqual(string: String) -> Bool {
        return self.toString == string
    }

    public func isEqual(stringOfText text: DEText) -> Bool {
        return self.toString == text.toString
    }

    public var hashValue: Int {
        switch self {
        case .string(let string): return string.hash
        case .attributedString(let string): return string.hash
        }
    }

    public static func ==(lhs: DEText, rhs: DEText) -> Bool {
        switch (lhs, rhs) {
        case (.string(let lString), .string(let rString)): return lString == rString
        case (.attributedString(let lString), .attributedString(let rString)): return lString == rString
        default: return false
        }
    }

    /**
     Calculates size of text.
     */
    public func size(width: CGFloat) -> CGSize {
        let limitSize = CGSize(width: width, height: 0.0)
        let options: NSStringDrawingOptions = [NSStringDrawingOptions.usesLineFragmentOrigin]
        var size: CGSize = .zero
        switch self {
        case .string(let string):
            let bounds = (string as NSString).boundingRect(with: limitSize,
                                                           options: options,
                                                           attributes: nil,
                                                           context: nil)
            size = bounds.size

        case .attributedString(let attrString):
            size = attrString.boundingRect(with: limitSize, options:options, context: nil).size
        }

        size.width = ceil(width)
        size.height = ceil(size.height)
        return size
    }

    public init(_ string: String) {
        self = .string(string)
    }

    public init(_ attributedString: NSAttributedString) {
        self = .attributedString(attributedString)
    }

    public init(string: String, font: UIFont) {
        self = .attributedString(string.attributed(with: [NSAttributedStringKey.font.rawValue : font]))
    }
}

func createText(string: String) -> DEText {
    return DEText.string(string)
}

public protocol DETextRepresentable {
    func asDEText() -> DEText?
}

extension String: DETextRepresentable {
    public func asDEText() -> DEText? {
        return DEText.string(self)
    }
}

extension NSAttributedString: DETextRepresentable {
    public func asDEText() -> DEText? {
        return DEText.attributedString(self)
    }
}

public extension UILabel {
    var dlg_text: DEText? {
        get {
            if let attrText = self.attributedText {
                return DEText.attributedString(attrText)
            }
            else if let text = self.text {
                return DEText.string(text)
            }
            return nil
        }
        set {
            if let text = dlg_text {
                switch text {
                case .string(let string): self.text = string
                case .attributedString(let attrString): self.attributedText = attrString
                }
            }
            else {
                self.text = nil
            }
        }
    }
}


public extension UIButton {
    func set(titleText: DEText?, for state: UIControlState, animated: Bool = true) {
        
        let textChange: (()->()) = {
            if let titleText = titleText {
                switch titleText {
                case .attributedString(let attrString):
                    self.setAttributedTitle(attrString, for: state)
                case .string(let string):
                    self.setAttributedTitle(nil, for: state)
                    self.setTitle(string, for: state)
                }
            }
            else {
                self.setTitle(nil, for: state)
            }
        }
        
        if animated {
            // By default iOS animates title changes
            textChange()
        }
        else {
            // https://stackoverflow.com/questions/18946490/how-to-stop-unwanted-uibutton-animation-on-title-change
            var wereAnimationsEnabled = UIView.areAnimationsEnabled
            UIView.setAnimationsEnabled(false)
            textChange()
            self.layoutIfNeeded()
            UIView.setAnimationsEnabled(wereAnimationsEnabled)
        }
        
    }
}


