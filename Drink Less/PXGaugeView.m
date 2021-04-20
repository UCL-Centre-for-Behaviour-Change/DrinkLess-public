//
//  PXGaugeView.m
//  Gauge
//
//  Created by Edward Warrender on 18/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXGaugeView.h"
#import "AngleGradientLayer.h"
#import "PXAuditFeedbackHelper.h"
#import "drinkless-Swift.h"

static CGFloat const PXHeight = 210.0;
static CGFloat const PXRadius = PXWidth * 0.5;
static CGFloat const PXTitleWidth = 20.0;
static CGFloat const PXPercentileWidth = 30.0;
static CGFloat const PXLineWidth = 30.0;
static CGPoint const PXDialOrigin = {PXRadius, PXRadius};
static CGFloat const PXNeedleLeftOffset = 22.5;

static CGFloat const PXOriginAngle = M_PI * 0.5;
static CGFloat const PXTiltAngle = M_PI / 2.4;
static CGFloat const PXStartAngle = PXOriginAngle + PXTiltAngle;
static CGFloat const PXEndAngle = PXOriginAngle - PXTiltAngle;
static CGFloat const PXRadians = (PXEndAngle < PXStartAngle ? M_PI * 2.0 : 0.0) + PXEndAngle - PXStartAngle;

static CGFloat const PXFullRotationDuration = 2.5;

@interface PXGaugeView ()

@property (strong, nonatomic) CALayer *markerLayer;
@property (strong, nonatomic) CALayer *needleLayer;
@property (strong, nonatomic) CALayer *secondaryNeedleLayer;
@property (strong, nonatomic) AngleGradientLayer *gradientLayer;
@property (strong, nonatomic) UIView *percentileContainerView;
@property (strong, nonatomic) UIView *titlesContainerView;

@end

@implementation PXGaugeView

+ (CGFloat)heightForWidth:(CGFloat)width {
    return (width / PXWidth) * PXHeight;
}

- (void)initialConfiguration {
    [super initialConfiguration];
    
    self.contentView.frame = CGRectMake(0.0, 0.0, PXWidth, PXHeight);
    self.backgroundImageView.image = [UIImage imageNamed:@"gauge-bg"];
    
    CALayer *dialLayer = [CALayer layer];
    dialLayer.position = PXDialOrigin;
    [self.contentView.layer addSublayer:dialLayer];
    
    CGFloat radius = PXRadius - PXTitleWidth;
    self.gradientLayer = [AngleGradientLayer layer];
    self.gradientLayer.backgroundColor = [UIColor clearColor].CGColor;
    self.gradientLayer.opaque = NO;
    self.gradientLayer.colors = @[(id)[UIColor lightGrayColor].CGColor];
    self.gradientLayer.bounds = CGRectMake(0.0, 0.0, radius * 2.0, radius * 2.0);
    self.gradientLayer.transform = CATransform3DConcat(CATransform3DMakeRotation(M_PI * 0.5, 0.0, 0.0, 1.0),
                                                  CATransform3DMakeScale(-1.0, 1.0, 1.0));
    [dialLayer addSublayer:self.gradientLayer];
    dialLayer.mask = [self arcLayerWithRadius:radius];
    
    [self plotDashes:10];
    [self plotPercentiles];
    
    self.titlesContainerView = [[UIView alloc] init];
    [self.contentView addSubview:self.titlesContainerView];
    
    UIImageView *markerImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gauge-marker"]];
    [self setupNeedleApperance:markerImageView.layer];
    [self.contentView addSubview:markerImageView];
    self.markerLayer = markerImageView.layer;
    
    UIImageView *needleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gauge-needle"]];
    [self setupNeedleApperance:needleImageView.layer];
    [self.contentView addSubview:needleImageView];
    self.needleLayer = needleImageView.layer;
    
    UIImageView *dotImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gauge-pin"]];
    dotImageView.center = PXDialOrigin;
    [self.contentView addSubview:dotImageView];
    
    // Update interface for editing state
    self.editing = self.editing;
}


- (void)setSecondaryPercentileEnabled:(BOOL)secondaryPercentileEnabled {
    if (!self.secondaryNeedleLayer && secondaryPercentileEnabled) {
        UIImageView *secNeedleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gauge-needle-secondary"]];
        [self setupNeedleApperance:secNeedleImageView.layer];
        [self.contentView addSubview:secNeedleImageView];
        [self.contentView.layer insertSublayer:secNeedleImageView.layer below:self.needleLayer];
        self.secondaryNeedleLayer = secNeedleImageView.layer;
    }
}

- (void)setSecondaryPercentile:(float)percentile {
    BOOL hasChanged = (percentile != _secondaryPercentile);
    _secondaryPercentile = percentile;
    if (hasChanged) {
        // @see -updatedPercentile
        CGFloat decimal = self.secondaryPercentile / 100.0;
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        animation.fillMode = kCAFillModeForwards;
        animation.removedOnCompletion = NO;
        animation.toValue = @(PXStartAngle + (PXRadians * decimal));
        animation.duration = PXFullRotationDuration * decimal;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        animation.beginTime = CACurrentMediaTime() + 0.3;
        [self.secondaryNeedleLayer addAnimation:animation forKey:@"transform"];
        //[self.delegate gaugeValueChanged:self];
    }
}

- (void)updateGradient {
    NSMutableArray *locations = [NSMutableArray array];
    for (NSDictionary *dictionary in self.percentileColors) {
        NSNumber *percentile = dictionary[PXGaugePercentile];
        CGFloat location = percentile.floatValue / 100.0;
        location *= PXRadians / (M_PI * 2.0);
        location += PXTiltAngle / (M_PI * 2.0);
        [locations addObject:@(location)];
    }
    self.gradientLayer.colors = [self.percentileColors valueForKey:PXGaugeColor];
    self.gradientLayer.locations = locations;
}

- (CAShapeLayer *)arcLayerWithRadius:(CGFloat)radius {
    radius -= (PXLineWidth * 0.5);
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointZero radius:radius startAngle:PXStartAngle endAngle:PXEndAngle clockwise:YES].CGPath;
    shapeLayer.lineWidth = PXLineWidth;
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.strokeColor = [UIColor blackColor].CGColor;
    return shapeLayer;
}

- (void)setupNeedleApperance:(CALayer *)layer {
    layer.anchorPoint = CGPointMake(PXNeedleLeftOffset / layer.bounds.size.width, 0.5);
    layer.position = PXDialOrigin;
    layer.transform = CATransform3DMakeRotation(PXStartAngle, 0.0, 0.0, 1.0);
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOffset = CGSizeMake(0.0, 2.0);
    layer.shadowOpacity = 0.3;
    layer.shadowRadius = 2.0;
}

- (void)setEstimate:(CGFloat)estimate {
    [self setEstimate:estimate animated:NO];
}

- (void)setEstimate:(CGFloat)estimate animated:(BOOL)animated {
    CGFloat decimal = estimate / 100.0;
    CGFloat angle = PXStartAngle + (PXRadians * decimal);
    
    if (animated) {
        CGFloat previousDecimal = _estimate / 100.0;
        CGFloat previousAngle = PXStartAngle + (PXRadians * previousDecimal);
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        animation.fillMode = kCAFillModeForwards;
        animation.removedOnCompletion = NO;
        animation.fromValue = @(previousAngle);
        animation.toValue = @(angle);
        animation.duration = 0.8 * fabs(decimal - previousDecimal);
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        [self.markerLayer addAnimation:animation forKey:@"transform"];
    } else {
        [self.markerLayer removeAnimationForKey:@"transform"];
        self.markerLayer.transform = CATransform3DMakeRotation(angle, 0.0, 0.0, 1.0);
    }
    _estimate = estimate;
    [self.delegate gaugeValueChanged:self];
}

- (void)updatedPercentile {
    CGFloat decimal = self.percentile / 100.0;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.toValue = @(PXStartAngle + (PXRadians * decimal));
    animation.duration = PXFullRotationDuration * decimal;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    animation.beginTime = CACurrentMediaTime() + 0.3;
    [self.needleLayer addAnimation:animation forKey:@"transform"];
    [self.delegate gaugeValueChanged:self];
}

- (void)plotDashes:(NSUInteger)count {
    CGFloat outerRadius = PXRadius - PXTitleWidth;
    CGFloat middleRadius = outerRadius - (PXLineWidth * 0.4);
    CGFloat innerRadius = outerRadius - PXLineWidth;
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    CGFloat increment = 1.0 / count;
    
    for (NSUInteger i = 1; i < count; i++) {
        CGFloat decimal = increment * i;
        CGFloat angle = PXStartAngle + (PXRadians * decimal);
        
        CGFloat x = outerRadius * cosf(angle);
        CGFloat y = outerRadius * sinf(angle);
        CGPoint position = CGPointMake(x, y);
        [bezierPath moveToPoint:position];
        
        BOOL odd = i % 2;
        CGFloat radius = odd ? middleRadius : innerRadius;
        
        x = radius * cosf(angle);
        y = radius * sinf(angle);
        position = CGPointMake(x, y);
        [bezierPath addLineToPoint:position];
    }
    
    CAShapeLayer *dashesLayer = [CAShapeLayer layer];
    dashesLayer.strokeColor = [UIColor colorWithWhite:0.94 alpha:1.0].CGColor;
    dashesLayer.lineWidth = 2.0;
    dashesLayer.path = bezierPath.CGPath;
    dashesLayer.position = PXDialOrigin;
    [self.contentView.layer addSublayer:dashesLayer];
}

- (void)plotPercentiles {
    CGFloat radius = PXRadius - PXTitleWidth - PXLineWidth - (PXPercentileWidth * 0.5);
    
    self.percentileContainerView = [[UIView alloc] init];
    [self.contentView addSubview:self.percentileContainerView];
    
    for (NSUInteger percentile = 0; percentile <= 100; percentile += 20) {
        CGFloat decimal = percentile / 100.0;
        CGFloat angle = PXStartAngle + (PXRadians * decimal);
        CGFloat x = radius * cosf(angle);
        CGFloat y = radius * sinf(angle);
        CGPoint position = CGPointMake(PXDialOrigin.x + x, PXDialOrigin.y + y);
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.font = [UIFont systemFontOfSize:16.0];
        label.textColor = [UIColor blackColor];
        label.text = [NSString stringWithFormat:@"%lu", (long unsigned)percentile];
        [self.percentileContainerView addSubview:label];
        [label sizeToFit];
        label.center = position;
    }
}

- (void)setPercentileZones:(NSArray *)percentileZones {
    if (_percentileZones != percentileZones) {
        [self plotTitles:percentileZones];
    }
    _percentileZones = percentileZones;
}

- (void)plotTitles:(NSArray *)titles {
    for (UIView *subview in self.titlesContainerView.subviews) {
        [subview removeFromSuperview];
    }
    
    CGFloat radius = PXRadius - (PXTitleWidth * 0.5);
    
    __block CGFloat previousPercentile = 0.0f;
    [titles enumerateObjectsUsingBlock:^(NSDictionary *dictionary, NSUInteger index, BOOL *stop) {
        
        CGFloat percentile = [dictionary[PXGaugePercentile] floatValue];
        CGFloat midPercentile = previousPercentile + ((percentile - previousPercentile) * 0.5);
        previousPercentile = percentile;
        
        NSString *title = dictionary[PXGaugeTitle];
        UIFont *font = [UIFont systemFontOfSize:11.5];
        CGFloat stringLength = [title sizeWithAttributes:@{NSFontAttributeName: font}].width;
        
        CGFloat decimal = midPercentile / 100.0;
        CGFloat angle = PXStartAngle + (PXRadians * decimal);
        CGFloat circumference = M_PI * (radius * 2.0);
        CGFloat arcLength = circumference * (PXRadians / (M_PI * 2.0));
        
        // Shift back by half the string length so the text is in the middle
        angle -= ((stringLength * 0.5) / arcLength) * PXRadians;
        
        for (NSUInteger i = 0; i < title.length; i++) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.font = font;
            label.textColor = [UIColor blackColor];
            label.text = [title substringWithRange:NSMakeRange(i, 1)];
            [self.titlesContainerView addSubview:label];
            
            [label sizeToFit];
            CGFloat halfLabelWidth = label.bounds.size.width * 0.5;
            angle += (halfLabelWidth / arcLength) * PXRadians;
            
            CGFloat x = radius * cosf(angle);
            CGFloat y = radius * sinf(angle);
            CGPoint position = CGPointMake(PXDialOrigin.x + x, PXDialOrigin.y + y);
            
            // @CRASH
            [Analytics.shared logCrashMessage:@"PXGaugeView::plotTitle: crash on `label.center=position`"];
            [Analytics.shared logCrashInfo:@{
                @"titles": titles,
                @"title": title,
                @"decimal": @(decimal),
                @"angle": @(angle),
                @"circumference": @(circumference),
                @"arcLength": @(arcLength),
                @"label.text": label.text,
                @"x": @(x),
                @"y": @(y),
                @"halfLabelWidth": @(halfLabelWidth),
                @"position.x": @(position.x),
                @"position.y": @(position.y)
            }];
            
            label.center = position;
//            [Analytics.shared crashMe];
            label.layer.transform = CATransform3DMakeRotation(angle + (M_PI * 0.5), 0.0, 0.0, 1.0);
            angle += (halfLabelWidth / arcLength) * PXRadians;
        }
    }];
}

#pragma mark - Editing

- (void)setEditing:(BOOL)editing {
    self.needleLayer.hidden = editing;
    self.percentileContainerView.hidden = editing;
    self.userInteractionEnabled = editing;
    _editing = editing;
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    CGFloat percentile = [self clampedPercentileFromTouch:touches.anyObject];
    [self setEstimate:percentile animated:YES];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGFloat percentile = [self clampedPercentileFromTouch:touches.anyObject];
    [self setEstimate:percentile animated:NO];
}

- (CGFloat)clampedPercentileFromTouch:(UITouch *)touch {
    CGPoint location = [touch locationInView:self.contentView];
    CGPoint delta = CGPointMake(location.x - self.markerLayer.position.x,
                                location.y - self.markerLayer.position.y);
    CGFloat angle = atan2f(delta.y, delta.x);
    
    angle -= PXOriginAngle;
    if (angle < 0.0) {
        angle += (M_PI * 2.0);
    }
    
    CGFloat decimal = (angle - PXTiltAngle) / PXRadians;
    if (decimal < 0.0) {
        decimal = 0.0;
    } else if (decimal > 1.0) {
        decimal = 1.0;
    }
    return decimal * 100.0;
}

@end
