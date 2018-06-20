//
//  PXDeskView.h
//  Cards
//
//  Created by Edward Warrender on 02/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>
#import "PXCardView.h"

static CGFloat const PXWidth = 320.0;
static CGFloat const PXHalfWidth = PXWidth * 0.5;
static CGFloat const PXSceneHeight = 1000.0;
static CGFloat const PXCourtHeight = 480.0;
static CGFloat const PXZoneHeight = 100.0;
static CGPoint const PXCourtCenter = {PXHalfWidth, PXSceneHeight - (PXCourtHeight * 0.5)};
static CGFloat const PXAwayZoneY = PXSceneHeight - PXCourtHeight + PXZoneHeight;
static CGFloat const PXTowardZoneY = PXSceneHeight - PXZoneHeight;
static CGFloat const PXWallOffset = 50.0;

@protocol PXDeskViewDelegate;

@interface PXDeskView : UIView

@property (strong, nonatomic) NSArray *cards;
@property (nonatomic) NSInteger cardIndex;
@property (nonatomic) NSTimeInterval secondsRemaining;
@property (nonatomic) NSTimeInterval respawnTimeInterval;
@property (nonatomic, getter = isLandscapePositive) BOOL landscapePositive;
@property (nonatomic, getter = hasEndedRound) BOOL endedRound;
@property (nonatomic, getter = isLowGroup) BOOL lowGroup;

@property (strong, nonatomic) UIDynamicAnimator *animator;
@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) PXCardView *cardView;
@property (strong, nonatomic) UIView *awayIndictorView;
@property (strong, nonatomic) UIView *towardIndictorView;
@property (strong, nonatomic) CAShapeLayer *awayLineLayer;
@property (strong, nonatomic) CAShapeLayer *towardLineLayer;
@property (strong, nonatomic) UILabel *countdownLabel;
@property (strong, nonatomic) CAShapeLayer *ringLayer;

@property (weak, nonatomic) IBOutlet id <PXDeskViewDelegate> delegate;

- (void)initialConfiguration;
- (void)prepareRoundWithCountdown:(NSTimeInterval)countdown;
- (void)startRoundWithCompletion:(void (^)(void))completion;
- (void)endRoundWithCompletion:(void (^)(void))completion;
- (void)addNewCardWithCompletion:(void (^)(void))completion;
- (void)flingCardWithVelocity:(CGPoint)velocity;

@end

@protocol PXDeskViewDelegate <NSObject>

- (void)didFailTrial;
- (void)didPassTrial;

@end
