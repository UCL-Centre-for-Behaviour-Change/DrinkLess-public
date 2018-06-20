//
//  PXCardView.m
//  drinkless
//
//  Created by Edward Warrender on 16/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXCardView.h"

static CGFloat const PXAspectRatio = 16.0 / 12.0;
static CGFloat const PXMaxLength = 190.0;
static CGFloat const PXMinLength = PXMaxLength / PXAspectRatio;

@interface PXCardView ()

@property (strong, nonatomic) UIImageView *imageView;

@end

@implementation PXCardView

- (instancetype)initWithImage:(UIImage *)image landscape:(BOOL)isLandscape {
    CGFloat width = isLandscape ? PXMaxLength : PXMinLength;
    CGFloat height = isLandscape ? PXMinLength : PXMaxLength;
    CGRect frame = CGRectMake(0.0, 0.0, width, height);
    
    self = [super initWithFrame:frame];
    if (self) {
        CGRect insetFrame = CGRectInset(frame, 5.0, 5.0);
        self.imageView = [[UIImageView alloc] initWithFrame:insetFrame];
        self.imageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.image = image;
        [self addSubview:self.imageView];
        
        self.backgroundColor = [UIColor whiteColor];
        self.layer.shadowOffset = CGSizeMake(0.0, 3.0);
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowRadius = 1.5;
        self.layer.shadowOpacity = 0.2;
    }
    return self;
}

@end
