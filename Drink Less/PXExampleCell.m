//
//  PXExampleCell.m
//  drinkless
//
//  Created by Edward Warrender on 05/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXExampleCell.h"
#import "PXDashedBackgroundView.h"

@implementation PXExampleCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    PXDashedBackgroundView *backgroundView = [[PXDashedBackgroundView alloc] init];
    backgroundView.fillColor = [UIColor clearColor];
    backgroundView.cornerRadius = 5.0;
    backgroundView.lineWidth = 1.0;
    backgroundView.strokeColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    backgroundView.dashed = YES;
    self.backgroundView = backgroundView;
    
    PXDashedBackgroundView *selectedBackgroundView = [[PXDashedBackgroundView alloc] init];
    selectedBackgroundView.fillColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    selectedBackgroundView.cornerRadius = 5.0;
    self.selectedBackgroundView = selectedBackgroundView;
    
    [self updateAppearanceSelected:self.isSelected];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    [self updateAppearanceSelected:highlighted];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    [self updateAppearanceSelected:selected];
}

- (void)updateAppearanceSelected:(BOOL)selected {
    self.titleLabel.textColor = selected ? [UIColor whiteColor] : self.tintColor;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    
    [self updateAppearanceSelected:self.isSelected];
}

@end
