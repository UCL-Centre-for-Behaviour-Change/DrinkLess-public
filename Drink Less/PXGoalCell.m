//
//  PXGoalCell.m
//  drinkless
//
//  Created by Edward Warrender on 09/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXGoalCell.h"

@implementation PXGoalCell

+ (UINib *)nib {
    return [UINib nibWithNibName:NSStringFromClass(self) bundle:nil];
}

- (void)setShowProgress:(BOOL)showProgress {
    _showProgress = showProgress;
    
    if (showProgress) {
        if (!self.radialProgressLayer) {
            self.radialProgressLayer = [PXRadialProgressLayer layer];
            self.radialProgressLayer.fillColor = [UIColor drinkLessOrangeColor].CGColor;
            [self.contentView.layer addSublayer:self.radialProgressLayer];
        }
    }
    self.radialProgressLayer.hidden = !showProgress;
    self.iconImageView.hidden = showProgress;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.radialProgressLayer.frame = self.iconImageView.frame;
    
    UIView *guideView = self.titleLabel.superview;
    [guideView layoutIfNeeded];
    CGRect guideFrame = [self convertRect:guideView.frame fromView:self.contentView];
    UIEdgeInsets separatorInset = self.separatorInset;
    separatorInset.left = CGRectGetMinX(guideFrame);
    self.separatorInset = separatorInset;
}

@end
