//
//  DialogCell.swift
//  DialExt
//
//  Created by Aleksei Gordeev on 14/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

class DialogCell: UITableViewCell {
    
    @IBOutlet public private(set) var nameLabel: UILabel!
    
    @IBOutlet public private(set) var avatarView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
