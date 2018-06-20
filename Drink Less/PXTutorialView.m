//
//  PXTutorialView.m
//  drinkless
//
//  Created by Edward Warrender on 06/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXTutorialView.h"

static NSTimeInterval const PXStartDelay = 1.0;
static CGFloat const PXAwayOffsetMax = 40.0;
static CGFloat const PXTowardOffsetMax = 20.0;
static CGFloat const PXFlingSpeed = 300.0;
static CGFloat const PXFlingSpeedSquared = PXFlingSpeed * PXFlingSpeed;

@implementation PXTutorialView

- (void)initialConfiguration {
    [super initialConfiguration];
    
    CAGradientLayer *gradientLayer = (CAGradientLayer *)self.layer;
    gradientLayer.colors = nil;
    self.countdownLabel.hidden = YES;
    self.ringLayer.hidden = YES;
    self.respawnTimeInterval = 1.5;
}

- (void)setCards:(NSArray *)cards {
    [super setCards:cards];
    
    // The card denotes if the tutorial is demonstrating positive or negative
    if (cards.count == 1) {
        NSDictionary *dictionary = cards.firstObject;
        BOOL isPositive = [dictionary[@"positive"] boolValue];
        self.awayLineLayer.hidden = isPositive;
        self.towardLineLayer.hidden = !isPositive;
    }
}

- (void)addNewCardWithCompletion:(void (^)(void))completion {
    [super addNewCardWithCompletion:completion];
    
    [self performSelector:@selector(simulateDemo) withObject:nil afterDelay:PXStartDelay];
}

- (void)simulateDemo {
    if (!self.cardView) {
        return;
    }
    
    NSInteger randomPercentage = arc4random_uniform(100 + 1);
    CGFloat fraction = randomPercentage / 100.0;
    BOOL negative = arc4random_uniform(2);
    if (negative) {
        fraction *= -1.0;
    }
    CGFloat xOffset = (self.cardView.isPositive ? PXTowardOffsetMax : PXAwayOffsetMax) * fraction;
    CGFloat midY = CGRectGetMidY(self.cardView.bounds);
    CGFloat awaySnapY = PXAwayZoneY - midY;
    CGFloat towardSnapY = PXTowardZoneY + midY;
    CGPoint point = CGPointMake(PXHalfWidth + xOffset, self.cardView.isPositive ? towardSnapY : awaySnapY);
    
    CGPoint delta = CGPointMake(point.x - self.cardView.center.x, point.y - self.cardView.center.y);
    CGFloat squaredDistance = (delta.x * delta.x) + (delta.y * delta.y);
    CGFloat ratio = PXFlingSpeedSquared / squaredDistance;
    CGPoint velocity = CGPointMake(delta.x * ratio, delta.y * ratio);
    
    [UIView animateWithDuration:(1.0 / ratio) delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.cardView.center = point;
    } completion:^(BOOL finished) {
        [self.animator updateItemUsingCurrentState:self.cardView];
        [self flingCardWithVelocity:velocity];
    }];
}

@end
