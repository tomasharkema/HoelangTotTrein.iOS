//
//  PickerCellView.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 15-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import UIKit

class PickerCellView : UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        selectionStyle = UITableViewCellSelectionStyle.None
    }
    
    var station:Station! {
        didSet {
            nameLabel.text = station.name.lang
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        nameLabel.textColor = selected ? UIColor.blackColor() : UIColor.whiteColor()
        contentView.backgroundColor = selected ? UIColor.whiteColor().colorWithAlphaComponent(0.5) : UIColor.clearColor()
        backgroundColor = UIColor.clearColor()
        super.setSelected(selected, animated: animated)
    }
}
