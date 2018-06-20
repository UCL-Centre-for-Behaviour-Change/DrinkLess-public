//
//  PXInfographicView.m
//  drinkless
//
//  Created by Edward Warrender on 25/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXInfographicView.h"

@implementation PXInfographicView

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
    self.clipsToBounds = NO;
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    
    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.contentView.opaque = NO;
    [self addSubview:self.contentView];
    
    self.backgroundImageView = [[UIImageView alloc] init];
    self.backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.backgroundImageView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_backgroundImageView);
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_backgroundImageView]" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_backgroundImageView]" options:0 metrics:nil views:views]];
    
    // Subclasses must call super
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.bounds.size.width != self.previousWidth) {
        self.previousWidth = self.bounds.size.width;
        CGFloat scale = self.bounds.size.width / PXWidth;
        self.contentView.transform = CGAffineTransformMakeScale(scale, scale);
        [self invalidateIntrinsicContentSize];
        [self setNeedsLayout];
    }
    self.contentView.center = CGPointMake(self.frame.size.width * 0.5,
                                          self.frame.size.height * 0.5);
}

- (CGSize)intrinsicContentSize {
    return self.contentView.frame.size;
}

- (void)setPercentileColors:(NSArray *)percentileColors {
    _percentileColors = percentileColors;
    [self updateGradient];
}

- (void)updateGradient {
    // Overidded by subclasses
}

- (void)setPercentile:(CGFloat)percentile {
    BOOL hasChanged = (percentile != _percentile);
    _percentile = percentile;
    if (hasChanged) {
        [self updatedPercentile];
    }
}

- (void)updatedPercentile {
    // Overidded by subclasses
}

@end
