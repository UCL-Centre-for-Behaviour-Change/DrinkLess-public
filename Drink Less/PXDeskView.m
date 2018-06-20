//
//  PXDeskView.m
//  Cards
//
//  Created by Edward Warrender on 02/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXDeskView.h"
#import "PXCardView.h"

@interface PXDeskView ()

@property (strong, nonatomic) CAGradientLayer *awayMaskLayer;
@property (strong, nonatomic) CAGradientLayer *towardMaskLayer;
@property (strong, nonatomic) UICollisionBehavior *collisionBehavior;
@property (strong, nonatomic) UIAttachmentBehavior *attachementBehavior;
@property (strong, nonatomic) UIPanGestureRecognizer *gestureRecognizer;
@property (nonatomic) CGPoint offset;
@property (nonatomic) CGRect previousBounds;
@property (nonatomic) NSTimeInterval countdownDuration;

@end

@implementation PXDeskView

+ (Class)layerClass {
    return [CAGradientLayer class];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
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
    CAGradientLayer *gradientLayer = (CAGradientLayer *)self.layer;
    gradientLayer.colors = @[(id)[UIColor colorWithWhite:0.88 alpha:1.0].CGColor,
                             (id)[UIColor colorWithWhite:0.98 alpha:1.0].CGColor];
    gradientLayer.locations = @[@0.2, @0.6];
    
    self.awayMaskLayer = [CAGradientLayer layer];
    self.awayMaskLayer.colors = @[(id)[UIColor blackColor].CGColor,
                                  (id)[UIColor clearColor].CGColor];
    
    self.awayIndictorView = [[UIView alloc] initWithFrame:CGRectZero];
    self.awayIndictorView.layer.zPosition = -999;
    self.awayIndictorView.backgroundColor = [UIColor clearColor];
    self.awayIndictorView.opaque = NO;
    self.awayIndictorView.alpha = 0.5;
    self.awayIndictorView.layer.mask = self.awayMaskLayer;
    [self addSubview:self.awayIndictorView];
    
    self.towardMaskLayer = [CAGradientLayer layer];
    self.towardMaskLayer.colors = @[(id)[UIColor clearColor].CGColor,
                                    (id)[UIColor blackColor].CGColor];
    
    self.towardIndictorView = [[UIView alloc] initWithFrame:CGRectZero];
    self.towardIndictorView.layer.zPosition = -999;
    self.towardIndictorView.backgroundColor = [UIColor clearColor];
    self.towardIndictorView.opaque = NO;
    self.towardIndictorView.alpha = 0.5;
    self.towardIndictorView.layer.mask = self.towardMaskLayer;
    self.towardIndictorView.layer.anchorPoint = CGPointMake(0.5, 1.0);
    [self addSubview:self.towardIndictorView];
    
    self.contentView = [[UIView alloc] init];
    self.contentView.layer.anchorPoint = CGPointMake(0.5, 1.0);
    self.contentView.frame = CGRectMake(0.0, 0.0, PXWidth, PXSceneHeight);
    self.contentView.backgroundColor = [UIColor clearColor];
    self.contentView.opaque = NO;
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = 1.0 / -250.0;
    transform = CATransform3DRotate(transform, M_PI * 0.15, 0.75, 0.0, 0.0);
    self.contentView.layer.transform = transform;
    [self addSubview:self.contentView];
    
    CAGradientLayer *maskLayer = [CAGradientLayer layer];
    maskLayer.colors = @[(id)[UIColor clearColor].CGColor,
                         (id)[UIColor blackColor].CGColor];
    maskLayer.locations = @[@0.05, @0.8];
    maskLayer.frame = [self convertRect:self.contentView.frame toView:self.contentView];
    self.contentView.layer.mask = maskLayer;
    
    CGRect ringFrame = CGRectMake(0.0, 0.0, PXWidth * 0.5, PXWidth * 0.5);
    
    self.ringLayer = [CAShapeLayer layer];
    CGRect offsetFrame = CGRectMake(-ringFrame.size.width * 0.5, -ringFrame.size.height * 0.5, ringFrame.size.width, ringFrame.size.height);
    self.ringLayer.path = [UIBezierPath bezierPathWithOvalInRect:offsetFrame].CGPath;
    self.ringLayer.position = PXCourtCenter;
    self.ringLayer.fillColor = [UIColor clearColor].CGColor;
    self.ringLayer.opaque = NO;
    self.ringLayer.lineWidth = 2.0;
    self.ringLayer.strokeColor = [UIColor blackColor].CGColor;
    self.ringLayer.transform = CATransform3DMakeRotation(M_PI * -0.5, 0.0, 0.0, 1.0);
    self.ringLayer.opacity = 0.15;
    [self.contentView.layer addSublayer:self.ringLayer];
    
    self.countdownLabel = [[UILabel alloc] initWithFrame:ringFrame];
    self.countdownLabel.center = PXCourtCenter;
    self.countdownLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:80.0];
    self.countdownLabel.textAlignment = NSTextAlignmentCenter;
    self.countdownLabel.textColor = [UIColor blackColor];
    self.countdownLabel.alpha = 0.15;
    [self.contentView addSubview:self.countdownLabel];
    
    self.gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pannedWithGestureRecognizer:)];
    [self addGestureRecognizer:self.gestureRecognizer];
    
    self.awayLineLayer = [self createLineLayer];
    self.awayLineLayer.position = CGPointMake(PXHalfWidth, PXAwayZoneY);
    [self.contentView.layer addSublayer:self.awayLineLayer];
    
    self.towardLineLayer = [self createLineLayer];
    self.towardLineLayer.position = CGPointMake(PXHalfWidth, PXTowardZoneY);
    [self.contentView.layer addSublayer:self.towardLineLayer];
    
    self.respawnTimeInterval = 0.1;
    
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.contentView];
    self.collisionBehavior = [[UICollisionBehavior alloc] init];
    [self.animator addBehavior:self.collisionBehavior];
    
    self.endedRound = YES;
}

- (CAShapeLayer *)createLineLayer {
    UIBezierPath *linePath = [UIBezierPath bezierPath];
    [linePath moveToPoint:CGPointMake(-PXHalfWidth, 0.0)];
    [linePath addLineToPoint:CGPointMake(PXHalfWidth, 0.0)];
    
    CAShapeLayer *lineLayer = [CAShapeLayer layer];
    lineLayer.lineWidth = 6.0;
    lineLayer.strokeColor = [UIColor blackColor].CGColor;
    lineLayer.lineDashPattern = @[@6, @4];
    lineLayer.path = linePath.CGPath;
    lineLayer.opacity = 0.1;
    return lineLayer;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!CGRectEqualToRect(self.bounds, self.previousBounds)) {
        self.contentView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMaxY(self.bounds));
        
        self.awayMaskLayer.frame = CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height * 0.35);
        self.awayIndictorView.frame = self.awayMaskLayer.frame;
        
        self.towardMaskLayer.frame = CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height * 0.3);
        self.towardIndictorView.frame = self.towardMaskLayer.frame;
        self.towardIndictorView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMaxY(self.bounds));
        
        CGFloat scale = CGRectGetHeight(self.bounds) / CGRectGetHeight(self.contentView.frame);
        CATransform3D scaleTransform = CATransform3DMakeAffineTransform(CGAffineTransformMakeScale(scale, scale));
        CATransform3D transform = self.contentView.layer.transform;
        self.contentView.layer.transform = CATransform3DConcat(transform, scaleTransform);
        
        // Collision boundary
        CGFloat topY = 0.0;
        CGFloat leftX = -PXWallOffset;
        CGFloat bottomY = self.bounds.size.height;
        CGFloat rightX = self.bounds.size.width + PXWallOffset;
        CGPoint topLeftPoint = [self convertPoint:CGPointMake(leftX, topY) toView:self.contentView];
        CGPoint bottomLeftPoint = [self convertPoint:CGPointMake(leftX, bottomY) toView:self.contentView];
        CGPoint topRightPoint = [self convertPoint:CGPointMake(rightX, topY) toView:self.contentView];
        CGPoint bottomRightPoint = [self convertPoint:CGPointMake(rightX, bottomY) toView:self.contentView];
        
        [self.collisionBehavior removeAllBoundaries];
        [self.collisionBehavior addBoundaryWithIdentifier:@"leftWall" fromPoint:topLeftPoint toPoint:bottomLeftPoint];
        [self.collisionBehavior addBoundaryWithIdentifier:@"rightWall" fromPoint:topRightPoint toPoint:bottomRightPoint];
    }
    self.previousBounds = self.bounds;
}

#pragma mark - Game State

- (void)prepareRoundWithCountdown:(NSTimeInterval)countdown {
    self.countdownDuration = countdown;
}

- (void)startRoundWithCompletion:(void (^)(void))completion {
    self.endedRound = NO;
    [self addNewCardWithCompletion:completion];
    self.gestureRecognizer.enabled = YES;
}

- (void)endRoundWithCompletion:(void (^)(void))completion {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.gestureRecognizer.enabled = NO;
    self.endedRound = YES;
    [self removeCardWithCompletion:^{
        [self.animator removeAllBehaviors];
        if (completion) completion();
    }];
}

- (void)setSecondsRemaining:(NSTimeInterval)secondsRemaining {
    self.countdownLabel.text = [NSString stringWithFormat:@"%.f", secondsRemaining];
    self.ringLayer.strokeEnd = (secondsRemaining / self.countdownDuration);
    _secondsRemaining = secondsRemaining;
}

- (void)setCards:(NSArray *)cards {
    _cards = cards;
}

- (void)addNewCardWithCompletion:(void (^)(void))completion {
    self.cardIndex = arc4random_uniform((u_int32_t)self.cards.count);
    
    NSDictionary *dictionary = self.cards[self.cardIndex];
    NSString *imageName = dictionary[@"imageName"];
    UIImage *image = [UIImage imageNamed:imageName];
    
    BOOL isPositive;
    if (self.isLowGroup) {
        // Low group can push either away
        isPositive = arc4random_uniform(2);
    } else {
        // High group always pushes away alcohol
        isPositive = [dictionary[@"positive"] boolValue];
    }
    BOOL isLandscape = (isPositive == self.isLandscapePositive);
    
    self.cardView = [[PXCardView alloc] initWithImage:image landscape:isLandscape];
    self.cardView.positive = isPositive;
    self.cardView.center = PXCourtCenter;
    [self.contentView addSubview:self.cardView];
    
    // Max angle of 10 degrees with 100 levels of variance
    NSInteger randomPercentage = arc4random_uniform(100 + 1);
    CGFloat fraction = randomPercentage / 100.0;
    BOOL negative = arc4random_uniform(2);
    if (negative) {
        fraction *= -1.0;
    }
    CGFloat maxAngle = 10.0 * (M_PI / 180.0);
    self.cardView.layer.transform = CATransform3DMakeRotation(maxAngle * fraction, 0.0, 0.0, 1.0);
    
    [self.collisionBehavior addItem:self.cardView];
    
    self.cardView.alpha = 0.0;
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.cardView.alpha = 1.0;
    } completion:^(BOOL finished) {
        if (completion) completion();
    }];
    
    self.gestureRecognizer.enabled = YES;
}

- (void)removeCardWithCompletion:(void (^)(void))completion {
    PXCardView *removingCardView = self.cardView;
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        removingCardView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [removingCardView removeFromSuperview];
        if (completion) completion();
    }];
}

#pragma mark - UIPanGestureRecognizer

- (void)pannedWithGestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self.animator removeBehavior:self.cardView.flingBehavior];
        
        CGPoint location = [gestureRecognizer locationInView:self.contentView];
        self.offset = CGPointMake(self.cardView.center.x - location.x, self.cardView.center.y - location.y);
        self.attachementBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.cardView
                                                             attachedToAnchor:self.cardView.center];
        [self.animator addBehavior:self.attachementBehavior];
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint location = [gestureRecognizer locationInView:self.contentView];
        location.x += self.offset.x;
        location.y += self.offset.y;
        self.attachementBehavior.anchorPoint = location;
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self.animator removeBehavior:self.attachementBehavior];
        
        CGPoint velocity = [gestureRecognizer velocityInView:self];
        [self flingCardWithVelocity:velocity];
    }
}

- (void)flingCardWithVelocity:(CGPoint)velocity {
    if (!self.cardView) {
        return;
    }
    
    [self.animator removeBehavior:self.cardView.flingBehavior];
    self.cardView.flingBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.cardView]];
    [self.cardView.flingBehavior addLinearVelocity:velocity forItem:self.cardView];
    self.cardView.flingBehavior.resistance = 10.0;
    self.cardView.flingBehavior.angularResistance = 10.0;
    
    __weak typeof(self) weakSelf = self;
    __block PXCardView *flungCardView = self.cardView;
    __block BOOL hasBeenTriggered = NO;
    self.cardView.flingBehavior.action = ^{
        if (hasBeenTriggered) {
            return;
        }
        BOOL isAway = (CGRectGetMaxY(weakSelf.cardView.frame) <= PXAwayZoneY);
        BOOL isToward = (CGRectGetMinY(weakSelf.cardView.frame) >= PXTowardZoneY);
        hasBeenTriggered = (isAway || isToward);
        if (hasBeenTriggered && !weakSelf.hasEndedRound) {
            BOOL correct = (flungCardView.isPositive == isToward);
            correct ? [weakSelf.delegate didPassTrial] : [weakSelf.delegate didFailTrial];
            
            UIView *view = isAway ? weakSelf.awayIndictorView : weakSelf.towardIndictorView;
            UIColor *color = correct ? [UIColor colorWithRed:0.5 green:2.0 blue:0.0 alpha:1.0] : [UIColor colorWithRed:1.0 green:0.25 blue:0.0 alpha:1.0];
            [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                view.backgroundColor = color;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                    view.backgroundColor = [UIColor clearColor];
                    flungCardView.alpha = 0.0;
                } completion:^(BOOL finished) {
                    [weakSelf.animator removeBehavior:flungCardView.flingBehavior];
                    [flungCardView removeFromSuperview];
                    flungCardView = nil;
                }];
            }];
            
            if (weakSelf.cardView == flungCardView) {
                weakSelf.cardView = nil;
            }
            [weakSelf.collisionBehavior removeItem:flungCardView];
            [weakSelf performSelector:@selector(addNewCardWithCompletion:) withObject:nil afterDelay:weakSelf.respawnTimeInterval];
            weakSelf.gestureRecognizer.enabled = NO;
        }
    };
    [self.animator addBehavior:self.cardView.flingBehavior];
}

@end
