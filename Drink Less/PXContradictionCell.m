//
//  PXWordCell.m
//  drinkless
//
//  Created by Edward Warrender on 05/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXContradictionCell.h"
#import "PXDashedBackgroundView.h"

@implementation PXContradictionCell

+ (UINib *)nib {
    return [UINib nibWithNibName:NSStringFromClass(self) bundle:nil];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    PXDashedBackgroundView *backgroundView = [[PXDashedBackgroundView alloc] init];
    backgroundView.fillColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    backgroundView.cornerRadius = 5.0;
    backgroundView.lineWidth = 1.0;
    backgroundView.strokeColor = [UIColor grayColor];
    backgroundView.dashed = YES;
    self.backgroundView = backgroundView;
    
    PXDashedBackgroundView *selectedBackgroundView = [[PXDashedBackgroundView alloc] init];
    selectedBackgroundView.fillColor = [UIColor colorWithRed:213/255.0 green:84/255.0 blue:67/255.0 alpha:0.5];
    selectedBackgroundView.cornerRadius = 5.0;
    selectedBackgroundView.lineWidth = 1.0;
    selectedBackgroundView.strokeColor = [UIColor colorWithRed:213/255.0 green:84/255.0 blue:67/255.0 alpha:1.0];
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
    self.titleLabel.textColor = selected ? [UIColor whiteColor] : [UIColor grayColor];
}

@end
