//
//  PXWeekDrinkCell.m
//  drinkless
//
//  Created by Edward Warrender on 21/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXWeekDrinkCell.h"

@implementation PXWeekDrinkCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.quantityLabel.textColor = [UIColor drinkLessGreenColor];
    
    CALayer *circleLayer = self.iconImageView.superview.layer;
    circleLayer.cornerRadius = CGRectGetMidX(circleLayer.bounds);
    circleLayer.rasterizationScale = [UIScreen mainScreen].scale;
    circleLayer.shouldRasterize = YES;
}

@end
