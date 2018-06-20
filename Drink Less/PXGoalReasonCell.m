//
//  PXGoalReasonCell.m
//  drinkless
//
//  Created by Edward Warrender on 27/04/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXGoalReasonCell.h"

@implementation PXGoalReasonCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.explanationLabel.textColor = [UIColor drinkLessGreenColor];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.explanationLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.explanationLabel.bounds);
    
    UIView *guideView = self.titleLabel.superview;
    [guideView layoutIfNeeded];
    CGRect guideFrame = [self convertRect:guideView.frame fromView:self.contentView];
    UIEdgeInsets separatorInset = self.separatorInset;
    separatorInset.left = CGRectGetMinX(guideFrame);
    self.separatorInset = separatorInset;
}

@end
