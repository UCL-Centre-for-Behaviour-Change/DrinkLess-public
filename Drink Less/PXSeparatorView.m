//
//  PXSeparatorView.m
///  drinkless
//
//  Created by Edward Warrender on 05/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXSeparatorView.h"

@implementation PXSeparatorView

- (id)init {
    self = [super init];
    if (self) {
        [self initialConfiguration];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initialConfiguration];
}

- (void)initialConfiguration {
    if (!self.backgroundColor) {
        self.backgroundColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    }
}

- (CGSize)intrinsicContentSize {
    CGFloat pixel = 1.0 / [UIScreen mainScreen].scale;
    return CGSizeMake(pixel, pixel);
}

@end
