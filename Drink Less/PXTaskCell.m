//
//  PXTaskCell.m
//  drinkless
//
//  Created by Edward Warrender on 19/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXTaskCell.h"

@interface PXTaskCell ()

@property (weak, nonatomic) IBOutlet UIView *dotView;
@property (strong, nonatomic) CALayer *dotLayer;

@end

@implementation PXTaskCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.tintColor = [UIColor whiteColor];
    
    self.dotLayer = [CALayer layer];
    self.dotLayer.anchorPoint = CGPointZero;
    self.dotLayer.bounds = self.dotView.bounds;
    self.dotLayer.cornerRadius = CGRectGetMidX(self.dotView.bounds);
    self.dotLayer.rasterizationScale = [UIScreen mainScreen].scale;
    self.dotLayer.shouldRasterize = YES;
    [self.dotView.layer addSublayer:self.dotLayer];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIView *guideView = self.titleLabel;
    [guideView layoutIfNeeded];
    CGRect guideFrame = [self convertRect:guideView.frame fromView:self.contentView];
    UIEdgeInsets separatorInset = self.separatorInset;
    separatorInset.left = CGRectGetMinX(guideFrame);
    self.separatorInset = separatorInset;
}

#pragma mark - Properties

- (void)setDotColor:(UIColor *)dotColor {
    _dotColor = dotColor;
    
    self.dotLayer.backgroundColor = dotColor.CGColor;
}

- (void)setCompleted:(BOOL)completed {
    _completed = completed;
    
    [UIView performWithoutAnimation:^{
        self.titleLabel.textColor = completed ? [UIColor whiteColor] : [UIColor blackColor];
        self.dotColor = completed ? [UIColor whiteColor] : [UIColor drinkLessGreenColor];
        self.backgroundColor = completed ? [UIColor drinkLessGreenColor] : [UIColor whiteColor];
        self.accessoryType = completed ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryDisclosureIndicator;
    }];
}

@end
