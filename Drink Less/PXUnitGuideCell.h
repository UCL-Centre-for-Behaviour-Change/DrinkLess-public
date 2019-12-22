//
//  PXUnitGuideCell.h
//  drinkless
//
//  Created by Edward Warrender on 16/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface PXUnitGuideCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *caloriesLabel;
@property (weak, nonatomic) IBOutlet UILabel *abvLabel;
@property (weak, nonatomic) IBOutlet UIView *unitsBadgeView;
@property (weak, nonatomic) IBOutlet UILabel *unitsValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *unitsTitleLabel;

@end
