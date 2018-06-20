//
//  PXDrinkLogCell.m
//  drinkless
//
//  Created by Edward Warrender on 14/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXDrinkLogCell.h"

@implementation PXDrinkLogCell

- (void)didMoveToWindow {
    [super didMoveToWindow];
    
    self.quantityLabel.textColor = self.tintColor;
}

@end
