
//
//  PXEstimateCell.m
//  drinkless
//
//  Created by Edward Warrender on 29/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXEstimateCell.h"

@interface PXEstimateCell () <PXGaugeViewDelegate>

@end

@implementation PXEstimateCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.gaugeView.editing = YES;
    self.gaugeView.delegate = self;
}

- (void)startHintAnimation {
    self.hintLabel.text = @"Tap or drag the dial";
    self.hintLabel.alpha = 0.0;
    [UIView animateKeyframesWithDuration:1.0
                                   delay:0.0
                                 options:UIViewKeyframeAnimationOptionAutoreverse | UIViewKeyframeAnimationOptionRepeat
                              animations:^{
                                  [UIView addKeyframeWithRelativeStartTime:0.0
                                                          relativeDuration:1.0
                                                                animations:^{
                                                                    self.hintLabel.alpha = 1.0;
                                                                }];
                              } completion:^(BOOL finished) {
                              }];
}

#pragma mark - PXGaugeViewDelegate

- (void)gaugeValueChanged:(PXGaugeView *)gaugeView {
    [self.hintLabel.layer removeAllAnimations];
    self.hintLabel.alpha = 1.0;
    [self.delegate updatedGaugeForEstimateCell:self];
}

@end
