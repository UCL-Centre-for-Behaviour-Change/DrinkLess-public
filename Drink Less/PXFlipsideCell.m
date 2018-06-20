//
//  PXFlipsideCell.m
//  drinkless
//
//  Created by Edward Warrender on 11/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXFlipsideCell.h"

@implementation PXFlipsideCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.clipsToBounds = NO;
    self.contentView.clipsToBounds = NO;
    
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = 1.0 / -250.0;
    
    self.positiveFlipView = [PXFlipView flipViewPositive:YES];
    self.positiveFlipView.layer.zPosition = 1.0;
    self.positiveFlipView.layer.anchorPoint = CGPointMake(0.5, 1.0);
    self.positiveFlipView.layer.transform = transform;
    self.positiveFlipView.layer.doubleSided = NO;
    [self.contentView addSubview:self.positiveFlipView];
    
    self.negativeFlipView = [PXFlipView flipViewPositive:NO];
    self.negativeFlipView.layer.zPosition = 2.0;
    self.negativeFlipView.layer.anchorPoint = CGPointMake(0.5, 0.0);
    self.negativeFlipView.layer.transform = transform;
    self.negativeFlipView.layer.doubleSided = NO;
    [self.contentView addSubview:self.negativeFlipView];
    
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat pixelGap = 1.0 / [UIScreen mainScreen].scale;
    CGFloat width = CGRectGetWidth(self.contentView.bounds);
    CGFloat height = floorf((self.contentView.bounds.size.height - pixelGap) / 2.0);
    self.positiveFlipView.frame = CGRectMake(0.0, 0.0, width, height);
    self.negativeFlipView.frame = CGRectMake(0.0, pixelGap + height, width, height);
}

- (void)animateFlipside {
    [self layoutIfNeeded];
    [self animateFlipView:self.positiveFlipView directionUp:NO withDelay:0.0];
    [self animateFlipView:self.negativeFlipView directionUp:YES withDelay:0.5];
}

- (void)animateFlipView:(UIView *)view directionUp:(BOOL)directionUp withDelay:(NSTimeInterval)delay {
    NSMutableArray *values = @[@(M_PI * 0.5), @(M_PI * -0.025), @(M_PI * 0.0125), @0].mutableCopy;
    if (directionUp) {
        for (int i = 0; i < values.count; i++) {
            NSNumber *value = values[i];
            value = @(value.floatValue * -1.0);
            values[i] = value;
        }
    }
    CGFloat startingValue = [values.firstObject floatValue];
    view.layer.transform = CATransform3DRotate(view.layer.transform, startingValue, 1.0, 0.0, 0.0);
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.x"];
    animation.duration = 1.0;
    animation.fillMode = kCAFillModeBoth;
    animation.removedOnCompletion = NO;
    animation.values = values;
    animation.keyTimes = @[@0.0, @0.5, @0.7, @1.0];
    animation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    animation.beginTime = CACurrentMediaTime() + delay;
    [view.layer addAnimation:animation forKey:@"transform"];
    
    view.alpha = 0.0;
    [UIView animateWithDuration:0.5
                          delay:delay
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         view.alpha = 1.0;
                     } completion:NULL];
}

@end
