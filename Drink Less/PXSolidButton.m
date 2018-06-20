//
//  PXSolidButton.m
//  SmokingDiary
//
//  Created by Edward Warrender on 17/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXSolidButton.h"

@implementation PXSolidButton

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
    self.layer.cornerRadius = 5.0;
    self.clipsToBounds = YES;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.layer.shouldRasterize = YES;
    self.normalColor = self.backgroundColor;
    self.keepLabelConfig = self.shouldKeepLabelConfig;
    [self setEnabled:self.isEnabled animated:NO];
}

- (void)setKeepLabelConfig:(BOOL)keepLabelConfig {
    _keepLabelConfig = keepLabelConfig;
    
    if (!keepLabelConfig) {
        self.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        self.titleLabel.numberOfLines = 1;
        self.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.titleLabel.minimumScaleFactor = 0.2;
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
}

- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = borderColor;
    
    self.layer.borderColor = borderColor.CGColor;
    if (self.borderWidth == 0.0) {
        // Default to one pixel
        self.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    } else {
        self.layer.borderWidth = self.borderWidth;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.isCircular) {
        self.layer.cornerRadius = CGRectGetMidX(self.bounds);
    }
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    
    if (!self.backgroundColor) {
        self.backgroundColor = self.tintColor;
        self.normalColor = self.backgroundColor;
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (self.isEnabled) {
        [self setHighlighted:highlighted animated:YES];
    }
}

- (void)setEnabled:(BOOL)enabled {
    [self setEnabled:enabled animated:NO];
}

- (void)setEnabled:(BOOL)enabled animated:(BOOL)animated {
    [super setEnabled:enabled];
    
    void (^updateBlock)() = ^{
        self.alpha = enabled ? 1.0 : 0.3;
    };
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            updateBlock();
        }];
    } else {
        updateBlock();
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    NSTimeInterval duration = animated ? 0.15 : 0.0;
    [UIView animateWithDuration:duration animations:^{
        self.alpha = highlighted ? 0.6 : 1.0;
    }];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setSelected:selected animated:YES];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    NSTimeInterval duration = animated ? 0.15 : 0.0;
    [UIView animateWithDuration:duration animations:^{
        if (selected && self.selectedColor) {
            self.backgroundColor = self.selectedColor;
        } else {
            self.backgroundColor = self.normalColor;
        }
    }];
}

@end
