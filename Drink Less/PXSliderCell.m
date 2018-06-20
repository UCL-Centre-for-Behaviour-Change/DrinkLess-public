//
//  PXSliderCell.m
//  drinkless
//
//  Created by Greg Plumbly on 19/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXSliderCell.h"

@implementation PXSliderCell

- (IBAction)sliderChanged:(id)sender {
    [self.delegate sliderCellChangedValue:self];
}

@end
