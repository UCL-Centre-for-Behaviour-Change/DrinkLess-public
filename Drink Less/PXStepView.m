//
//  PXStepView.m
//  drinkless
//
//  Created by Edward Warrender on 20/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXStepView.h"

static CGFloat const PXContainerWidth = 17.0;

@implementation PXStepView

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
    UIColor *defaultColor = [UIColor blackColor];
    
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = defaultColor;
    self.containerView.layer.cornerRadius = PXContainerWidth / 2.0;
    self.containerView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.containerView.layer.shouldRasterize = YES;
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.containerView.userInteractionEnabled = NO;
    [self addSubview:self.containerView];
    
    self.imageView = [[UIImageView alloc] init];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView.contentMode = UIViewContentModeCenter;
    [self.containerView addSubview:self.imageView];
    
    self.numberLabel = [[UILabel alloc] init];
    self.numberLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.numberLabel.textColor = [UIColor whiteColor];
    self.numberLabel.font = [UIFont systemFontOfSize:12.5];
    self.numberLabel.textAlignment = NSTextAlignmentCenter;
    [self.containerView addSubview:self.numberLabel];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.textColor = defaultColor;
    self.titleLabel.font = [UIFont systemFontOfSize:12.5];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.titleLabel];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_containerView, _imageView, _numberLabel, _titleLabel);
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_imageView]|" options:0 metrics:nil views:views]];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_numberLabel]|" options:0 metrics:nil views:views]];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_imageView]|" options:0 metrics:nil views:views]];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_numberLabel]|" options:0 metrics:nil views:views]];
    
    NSDictionary *metrics = @{@"PXContainerWidth": @(PXContainerWidth)};
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=0)-[_containerView(PXContainerWidth)]-(>=0)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_titleLabel]|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_containerView(PXContainerWidth)]-(>=0)-[_titleLabel]|" options:0 metrics:metrics views:views]];
}

@end
