//
//  PXLinkCell.m
//  drinkless
//
//  Created by Edward Warrender on 22/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXLinkCell.h"

@implementation PXLinkCell

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIView *guideView = self.titleLabel;
    [guideView layoutIfNeeded];
    CGRect guideFrame = [self convertRect:guideView.frame fromView:self.contentView];
    UIEdgeInsets separatorInset = self.separatorInset;
    separatorInset.left = CGRectGetMinX(guideFrame);
    self.separatorInset = separatorInset;
}

@end
