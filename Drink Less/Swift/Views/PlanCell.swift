//
//  PlanCell.swift
//  drinkless
//
//  Created by Hari Karam Singh on 28/02/2019.
// Copyright © 2019 UCL. All rights reserved.
//

import UIKit

class PlanCell: UICollectionViewCell {

    @IBOutlet var iconImgV:UIImageView?
    @IBOutlet var label:UILabel?
    override public var isSelected: Bool {
        didSet {
            iconImgV!.layer.borderColor = (isSelected ?  UIColor.drinkLessGreen() : UIColor.drinkLessLightGrey())?.cgColor
            let dsc = label!.font.fontDescriptor.withSymbolicTraits(isSelected ? [.traitBold] : [])
            label!.font = UIFont(descriptor: dsc!, size: label!.font.pointSize)
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Round the iconImgV
        iconImgV!.layer.cornerRadius = 50
        iconImgV!.layer.masksToBounds = true
        iconImgV!.layer.borderWidth = 3
        self.isSelected = isSelected ? true : false // set border colour
    }

}
