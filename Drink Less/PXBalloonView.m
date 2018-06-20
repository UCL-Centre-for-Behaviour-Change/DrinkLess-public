//
//  PXBalloonView.m
//  drinkless
//
//  Created by Edward Warrender on 19/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXBalloonView.h"
#import "PXExplosionLayer.h"

static CGFloat const PXWidth = 320.0;
static CGFloat const PXHeight = 346.0;
static CGFloat const PXInitialCapacity = 0.25;
static CGFloat const PXInitialInverseCapacity = 1.0 - PXInitialCapacity;
static CGFloat const PXStartingAngle = M_PI / 4.0;
static CGFloat const PXStartingLeftAngle = -PXStartingAngle;
static CGFloat const PXStartingRightAngle = PXStartingAngle;
static CGFloat const PXWobbleTitleAngle = M_PI / 35.0;
static CGFloat const PXWobbleLeftAngle = -PXWobbleTitleAngle;
static CGFloat const PXWobbleRightAngle = PXWobbleTitleAngle;
static CGFloat const PXFullTensionStrength = 0.8;

@interface PXBalloonView ()

@property (nonatomic) CGSize boundsSize;
@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) UIView *balloon;
@property (strong, nonatomic) UIImageView *head;
@property (strong, nonatomic) UIImageView *neck;
@property (strong, nonatomic) UIImageView *pump;
@property (strong, nonatomic) PXExplosionLayer *explosion;

@end

@implementation PXBalloonView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialConfiguration];
    }
    return self;
}

- (void)initialConfiguration {
    CGRect contentBounds = CGRectMake(0.0, 0.0, PXWidth, PXHeight);
    self.contentView = [[UIView alloc] initWithFrame:contentBounds];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.contentView.opaque = NO;
    [self addSubview:self.contentView];
    
    UIImage *pumpImage = [UIImage imageNamed:@"Pump-Nozzle"];
    self.pump = [[UIImageView alloc] initWithImage:pumpImage];
    self.pump.layer.anchorPoint = CGPointMake(0.5, 1.0);
    self.pump.center = CGPointMake(PXWidth / 2.0, PXHeight);
    [self.contentView addSubview:self.pump];
    
    self.balloon = [[UIView alloc] init];
    [self.contentView addSubview:self.balloon];
    
    CGFloat neckLevel = CGRectGetHeight(self.pump.frame) * 0.42;
    UIImage *neckImage = [UIImage imageNamed:@"Balloon-Neck"];
    self.neck = [[UIImageView alloc] initWithImage:neckImage];
    self.neck.contentMode = UIViewContentModeBottom;
    self.neck.layer.anchorPoint = CGPointMake(0.5, 1.0);
    self.neck.center = CGPointMake(PXWidth / 2.0, CGRectGetMinY(self.pump.frame) + neckLevel);
    [self.balloon addSubview:self.neck];
    
    CGFloat headAnchorOffsetY = 0.92;
    CGFloat headLevel = CGRectGetHeight(self.neck.frame) * 0.3;
    UIImage *headImage = [UIImage imageNamed:@"Balloon-Head"];
    self.head = [[UIImageView alloc] initWithImage:headImage];
    self.head.layer.anchorPoint = CGPointMake(0.5, headAnchorOffsetY);
    self.head.center = CGPointMake(PXWidth / 2.0, CGRectGetMinY(self.neck.frame) + headLevel);
    [self.balloon addSubview:self.head];
    
    self.explosion = [PXExplosionLayer layer];
    [self.layer addSublayer:self.explosion];
}

- (void)moveAway:(BOOL)away withCompletion:(void (^)(void))completion {
    [UIView animateWithDuration:0.8 animations:^{
        if (away) {
            self.balloon.center = CGPointMake(-PXWidth, -PXHeight / 3.0);
        } else {
            self.balloon.center = CGPointMake(0.0, -CGRectGetMidY(self.pump.bounds));
        }
    } completion:^(BOOL finished) {
        if (completion) completion();
    }];
}

- (void)attachToPump:(BOOL)attach withCompletion:(void (^)(void))completion {
    [UIView animateWithDuration:0.5 animations:^{
        if (attach) {
            self.balloon.center = CGPointZero;
        } else {
            self.balloon.center = CGPointMake(0.0, -CGRectGetMidY(self.pump.bounds));
        }
    } completion:^(BOOL finished) {
        if (completion) completion();
    }];
}

- (void)resetWithCompletion:(void (^)(void))completion {
    [self.head.layer removeAllAnimations];
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(0.15, 0.2);
    CGFloat angle = arc4random_uniform(2) ? PXStartingLeftAngle : PXStartingRightAngle;
    CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(angle);
    self.head.transform = CGAffineTransformConcat(scaleTransform, rotationTransform);
    self.head.hidden = NO;
    self.neck.image = [UIImage imageNamed:@"Balloon-Neck"];
    self.balloon.center = CGPointMake(PXWidth, -PXHeight / 3.0);
    
    [self moveAway:NO withCompletion:^{
        [self attachToPump:YES withCompletion:^{
            [UIView animateWithDuration:1.0 animations:^{
                self.head.transform = CGAffineTransformMakeScale(PXInitialCapacity, PXInitialCapacity);
            } completion:^(BOOL finished) {
                if (completion) completion();
            }];
        }];
    }];
}

- (void)inflateToCapacity:(CGFloat)capacity completion:(void (^)(void))completion {
    CGFloat scale = PXInitialCapacity + (PXInitialInverseCapacity * capacity);
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scale, scale);
    CGFloat angle = arc4random_uniform(2) ? PXWobbleLeftAngle : PXWobbleRightAngle;
    angle *= 1.0 - (scale * PXFullTensionStrength);
    CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(angle);
    
    [UIView animateWithDuration:0.5 delay:0.0 options:0 animations:^{
        self.head.transform = CGAffineTransformConcat(scaleTransform, rotationTransform);
    } completion:^(BOOL finished) {
        if (completion) completion();
        if (finished) {
            [UIView animateWithDuration:4.0
                                  delay:0.0
                 usingSpringWithDamping:0.3
                  initialSpringVelocity:0.0
                                options:0
                             animations:^{
                                 self.head.transform = scaleTransform;
                             }
                             completion:NULL];
        }
    }];
}

- (void)collectWithCompletion:(void (^)(void))completion {
    [self attachToPump:NO withCompletion:^{
        [self moveAway:YES withCompletion:completion];
    }];
    [UIView animateWithDuration:0.3 delay:0.0 options:0 animations:^{
        self.neck.transform = CGAffineTransformMakeScale(1.0, 0.7);
    } completion:^(BOOL finished) {
        self.neck.image = [UIImage imageNamed:@"Balloon-Neck-Tied"];
        [UIView animateWithDuration:0.5
                              delay:0.0
             usingSpringWithDamping:0.3
              initialSpringVelocity:0.0
                            options:0
                         animations:^{
                             self.neck.transform = CGAffineTransformIdentity;
                         } completion:NULL];
    }];
}

- (void)explodeWithCompletion:(void (^)(void))completion {
    [self.head.layer removeAllAnimations];
    self.head.hidden = YES;
    self.neck.image = [UIImage imageNamed:@"Balloon-Neck-Snapped"];
    self.explosion.emitterPosition = CGPointMake(CGRectGetMidX(self.head.frame), CGRectGetMidY(self.head.frame));
    self.explosion.emitting = YES;
    
    [UIView animateWithDuration:0.1 animations:^{
        self.neck.transform = CGAffineTransformMakeScale(1.0, 0.6);
    } completion:^(BOOL finished) {
        self.explosion.emitting = NO;
        [UIView animateWithDuration:1.0
                              delay:0.0
             usingSpringWithDamping:0.3
              initialSpringVelocity:0.0
                            options:0
                         animations:^{
                             self.neck.transform = CGAffineTransformIdentity;
                         } completion:^(BOOL finished) {
                             [self attachToPump:NO withCompletion:^{
                                 [self moveAway:YES withCompletion:completion];
                             }];
                         }];
    }];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!CGSizeEqualToSize(self.bounds.size, self.boundsSize)) {
        self.boundsSize = self.bounds.size;
        CGFloat widthScale = self.boundsSize.width / PXWidth;
        CGFloat heightScale = self.boundsSize.height / PXHeight;
        CGFloat minScale = MIN(widthScale, heightScale);
        self.contentView.transform = CGAffineTransformMakeScale(minScale, minScale);
        [self invalidateIntrinsicContentSize];
        [self setNeedsLayout];
    }
    self.contentView.center = CGPointMake(self.frame.size.width * 0.5,
                                          self.frame.size.height * 0.5);
}

- (CGSize)intrinsicContentSize {
    return self.contentView.frame.size;
}

@end
