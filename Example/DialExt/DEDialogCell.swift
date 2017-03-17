//
//  DEDialogCell.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 14/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

class DEDialogCell: UITableViewCell {
    
    @IBOutlet public private(set) var nameLabel: UILabel!
    @IBOutlet public private(set) var nameLabelContainer: UIView!
    
    @IBOutlet public private(set) var statusLabel: UILabel!
    @IBOutlet public private(set) var statusLabelContainer: UIView!
    
    @IBOutlet public private(set) var avatarView: UIImageView!
    
    @IBOutlet public private(set) var selectionImageView: UIImageView!
    
    public private(set) var selectionState: SelectionState = .default
    
    public func setSelectionState(_ state: SelectionState, animated: Bool = true) {
        self.selectionState = state
        
        updateSelectionState(animated: animated)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateSelectionState(animated: false)
    }

    public struct SelectionState {
        
        public static let `default`: SelectionState = {
            let selectedImage = UIImage(named: "circle_selected", in: Bundle.dialExtBundle, compatibleWith: nil)
            let deselectedImage = UIImage(named: "circle_deselected", in: Bundle.dialExtBundle, compatibleWith: nil)
            return SelectionState(selected: false, selectedImage: selectedImage, deselectedImage: deselectedImage)
        }()
        
        public var selected: Bool = false
        
        public var selectedImage: UIImage? = nil
        
        public var deselectedImage: UIImage? = nil
        
        public var proposedImage: UIImage? {
            return selected ? selectedImage : deselectedImage
        }
    }
    
    private func updateSelectionState(animated: Bool) {
        // change image, animate changes
        
        self.selectionImageView.image = self.selectionState.proposedImage
    }
}
