//
//  PXFlipView.m
//  drinkless
//
//  Created by Edward Warrender on 11/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXFlipView.h"

@implementation PXFlipView

+ (instancetype)flipViewPositive:(BOOL)positive {
    UINib *nib = [UINib nibWithNibName:@"PXFlipView" bundle:nil];
    PXFlipView *flipView = [nib instantiateWithOwner:nil options:nil].firstObject;
    if (positive) {
        flipView.titleLabel.layer.shadowColor = [UIColor drinkLessGreenColor].CGColor;
        flipView.overlayView.backgroundColor = [UIColor overlayGreen];
    } else {
        flipView.titleLabel.layer.shadowColor = [UIColor goalRedColor].CGColor;
        flipView.overlayView.backgroundColor = [UIColor overlayRed];
    }
    return flipView;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.titleLabel.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.titleLabel.layer.shouldRasterize = YES;
    self.titleLabel.layer.shadowRadius = 3.0;
    self.titleLabel.layer.shadowOpacity = 1.0;
    self.titleLabel.layer.shadowOffset = CGSizeMake(0.0, 0.0);
}

- (void)setOverlayHidden:(BOOL)overlayHidden {
    [self setOverlayHidden:overlayHidden animated:NO];
}

- (void)setOverlayHidden:(BOOL)overlayHidden animated:(BOOL)animated {
    _overlayHidden = overlayHidden;
    
    [UIView animateWithDuration:animated ? 0.4 : 0.0 animations:^{
        self.overlayView.alpha = overlayHidden ? 0.0 : 1.0;
    }];
    [UIView animateWithDuration:animated ? 0.8 : 0.0 delay:0.0 usingSpringWithDamping:0.5 initialSpringVelocity:0.0 options:0 animations:^{
        self.titleLabel.superview.transform = overlayHidden ? CGAffineTransformMakeScale(0.3, 0.3) : CGAffineTransformIdentity;
    } completion:nil];
}

@end
