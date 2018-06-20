//
//  PXDividerView.m
//  drinkless
//
//  Created by Edward Warrender on 29/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXDividerView.h"

@implementation PXDividerView

+ (Class)layerClass {
    return [CAGradientLayer class];
}

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
    CAGradientLayer *gradientLayer = (CAGradientLayer *)self.layer;
    gradientLayer.colors = @[(id)[UIColor clearColor].CGColor,
                             (id)[UIColor colorWithWhite:0.0 alpha:0.3].CGColor,
                             (id)[UIColor clearColor].CGColor];
    
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    gradientLayer.opaque = NO;
    gradientLayer.backgroundColor = [UIColor clearColor].CGColor;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(0.0, 1.0 / [UIScreen mainScreen].scale);
}

@end
