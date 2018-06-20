//
//  PXStepGuideCell.m
//  drinkless
//
//  Created by Edward Warrender on 15/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXStepGuideCell.h"

@implementation PXStepGuideCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    CALayer *layer = self.pictureImageView.layer;
    CGFloat radius = CGRectGetMidX(layer.bounds);
    layer.cornerRadius = radius;
    layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
    layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    layer.masksToBounds = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIView *containerView = self.titleLabel.superview;
    [containerView layoutIfNeeded];
    CGRect containerFrame = [self convertRect:containerView.frame fromView:self.contentView];
    UIEdgeInsets separatorInset = self.separatorInset;
    separatorInset.left = CGRectGetMinX(containerFrame);
    self.separatorInset = separatorInset;
}

- (void)setCompleted:(BOOL)completed {
    _completed = completed;
    
    self.titleLabel.textColor = completed ? [UIColor drinkLessGreenColor] : [UIColor grayColor];
    self.accessoryType = completed ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryDisclosureIndicator;
}

- (void)setVivid:(BOOL)vivid {
    _vivid = vivid;
    
    self.titleLabel.textColor = vivid ? [UIColor whiteColor] : [UIColor grayColor];
    self.detailLabel.textColor = vivid ? [UIColor whiteColor] : [UIColor colorWithWhite:0.6 alpha:1.0];
    self.backgroundColor = vivid ? [UIColor drinkLessGreenColor] : [UIColor whiteColor];
}

@end
