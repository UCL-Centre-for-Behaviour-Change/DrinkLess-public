//
//  PXGoalCell.h
//  drinkless
//
//  Created by Edward Warrender on 09/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>
#import "PXRadialProgressLayer.h"

@interface PXGoalCell : UITableViewCell

+ (UINib *)nib;

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (strong, nonatomic) PXRadialProgressLayer *radialProgressLayer;
@property (nonatomic, getter = shouldShowProgress) BOOL showProgress;

@end
