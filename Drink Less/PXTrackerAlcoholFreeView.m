//
//  PXTrackerAlcoholFreeView.m
//  drinkless
//
//  Created by Edward Warrender on 08/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXTrackerAlcoholFreeView.h"

@interface PXTrackerAlcoholFreeView ()

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightConstraint;
@property (nonatomic) CGFloat originalHeight;

@end

@implementation PXTrackerAlcoholFreeView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.originalHeight = self.heightConstraint.constant;
    
    self.titleLabel.textColor = [UIColor drinkLessGreenColor];
}

- (void)setCollapsed:(BOOL)collapsed {
    _collapsed = collapsed;
    
    self.heightConstraint.constant = collapsed ? 0 : self.originalHeight;
}

@end
