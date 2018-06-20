//
//  PXDiaryStreakCell.m
//  drinkless
//
//  Created by Edward Warrender on 16/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXDiaryStreakCell.h"

@interface PXDiaryStreakCell ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *spacingConstraint;
@property (nonatomic) CGFloat originalSpacing;

@end

@implementation PXDiaryStreakCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.originalSpacing = self.spacingConstraint.constant;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIView *guideView = self.titleLabel.superview;
    [guideView layoutIfNeeded];
    CGRect guideFrame = [self convertRect:guideView.frame fromView:self.contentView];
    UIEdgeInsets separatorInset = self.separatorInset;
    separatorInset.left = CGRectGetMinX(guideFrame);
    self.separatorInset = separatorInset;
}

- (void)showCurrentStreak:(NSInteger)currentStreak highestStreak:(NSInteger)highestStreak {
    BOOL hasTitle = currentStreak > 1;
    if (!hasTitle) {
        self.titleLabel.text = nil;
    } else {
        self.titleLabel.text = [NSString stringWithFormat:@"Keeping your diary %li days in a row", (long)currentStreak];
    }
    
    BOOL hasSubtitle = highestStreak > 1;
    if (!hasSubtitle) {
        self.subtitleLabel.text = nil;
    } else if (currentStreak == highestStreak) {
        self.subtitleLabel.text = @"This is your longest streak";
    } else {
//        just in a special case to show the same font size. See https://github.com/PortablePixels/DrinkLess/issues/146
        self.subtitleLabel.text = nil;
        self.titleLabel.text = [NSString stringWithFormat:@"Your longest streak was %li days", (long)highestStreak];

    }
    
    self.spacingConstraint.constant = hasTitle && hasSubtitle ? self.originalSpacing : 0.0;
}

@end
