//
//  PXOutlineButton.m
//  drinkless
//
//  Created by Edward Warrender on 10/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXOutlineButton.h"

@implementation PXOutlineButton

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
    self.adjustsImageWhenHighlighted = NO;
    self.adjustsImageWhenDisabled = NO;
    self.clipsToBounds = YES;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.layer.shouldRasterize = YES;
    self.layer.borderWidth = 1.0;
    
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self setHighlighted:self.isHighlighted animated:NO];
    [self setEnabled:self.isEnabled animated:NO];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    [self setHighlighted:highlighted animated:YES];
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    
    [self setEnabled:enabled animated:YES];
}

- (void)setEnabled:(BOOL)enabled animated:(BOOL)animated
{
    NSTimeInterval duration = animated ? 0.15 : 0.0;
    [UIView animateWithDuration:duration animations:^{
        self.alpha = [self alphaForState:self.state];
    }];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    NSTimeInterval duration = animated ? 0.15 : 0.0;
    [UIView animateWithDuration:duration animations:^{
        self.alpha = [self alphaForState:self.state];
        self.backgroundColor = highlighted ? self.tintColor : [UIColor whiteColor];
    }];
}

- (CGFloat)alphaForState:(UIControlState)state {
    switch (state) {
        case UIControlStateDisabled:
            return 0.3;
        default:{
            return 1.0;
        }
    }
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    
    self.layer.borderColor = self.tintColor.CGColor;
    if (self.isHighlighted) {
        self.backgroundColor = self.tintColor;
    }
    [self setTitleColor:self.tintColor forState:UIControlStateNormal];
}

@end
