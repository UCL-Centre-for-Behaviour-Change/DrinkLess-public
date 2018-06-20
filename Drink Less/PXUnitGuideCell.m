//
//  PXUnitGuideCell.m
//  drinkless
//
//  Created by Edward Warrender on 16/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXUnitGuideCell.h"
#import "PXDashedBackgroundView.h"

@implementation PXUnitGuideCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    PXDashedBackgroundView *backgroundView = [[PXDashedBackgroundView alloc] init];
    backgroundView.fillColor = [UIColor whiteColor];
    backgroundView.cornerRadius = 5.0;
    backgroundView.lineWidth = 1.0;
    backgroundView.strokeColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    self.backgroundView = backgroundView;
    
    self.unitsBadgeView.layer.cornerRadius = CGRectGetMidX(self.unitsBadgeView.bounds);
    self.unitsBadgeView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.unitsBadgeView.layer.shouldRasterize = YES;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    
    self.abvLabel.textColor = self.tintColor;
}

@end
