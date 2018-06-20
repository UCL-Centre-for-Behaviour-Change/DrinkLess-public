//
//  PXArrowView.m
//  drinkless
//
//  Created by Edward Warrender on 17/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXArrowView.h"

static CGSize const PXArrowTipSize = {8.0, 7.0};

@interface PXArrowView ()

@property (strong, nonatomic) CAShapeLayer *arrowLineLayer;
@property (strong, nonatomic) CAShapeLayer *arrowTipLayer;

@end

@implementation PXArrowView

- (id)init {
    self = [super init];
    if (self) {
        self.arrowLineLayer = [CAShapeLayer layer];
        self.arrowLineLayer.fillColor = [UIColor clearColor].CGColor;
        self.arrowLineLayer.strokeColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
        self.arrowLineLayer.lineWidth = 2.0;
        self.arrowLineLayer.lineDashPattern = @[@7.0, @3.5];
        self.arrowLineLayer.rasterizationScale = [UIScreen mainScreen].scale;
        self.arrowLineLayer.shouldRasterize = YES;
        [self.layer addSublayer:self.arrowLineLayer];
        
        self.arrowTipLayer = [CAShapeLayer layer];
        self.arrowTipLayer.bounds = CGRectMake(0.0, 0.0, PXArrowTipSize.width, PXArrowTipSize.height);
        self.arrowTipLayer.fillColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
        self.arrowTipLayer.anchorPoint = CGPointMake(0.0, 0.5);
        self.arrowTipLayer.path = [self arrowTipBezierPathWithSize:PXArrowTipSize].CGPath;
        self.arrowTipLayer.rasterizationScale = [UIScreen mainScreen].scale;
        self.arrowTipLayer.shouldRasterize = YES;
        [self.layer addSublayer:self.arrowTipLayer];
    }
    return self;
}

- (UIBezierPath *)arrowTipBezierPathWithSize:(CGSize)size {
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(0.0, 0.0)];
    [bezierPath addLineToPoint:CGPointMake(size.width, size.height / 2.0)];
    [bezierPath addLineToPoint:CGPointMake(0.0, size.height)];
    [bezierPath closePath];
    return bezierPath;
}

- (void)animateWithStartPoint:(CGPoint)startPoint midPoint:(CGPoint)midPoint endPoint:(CGPoint)endPoint {
    endPoint = CGPointMake(endPoint.x - self.arrowTipLayer.bounds.size.width, endPoint.y);
    self.arrowTipLayer.position = endPoint;
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:startPoint];
    [self addPoint:midPoint fromPreviousPoint:startPoint toNextPoint:endPoint withRadius:4.0 toBezierPath:bezierPath];
    [bezierPath addLineToPoint:endPoint];
    self.arrowLineLayer.path = bezierPath.CGPath;
    
    CFTimeInterval delay = 0.3;
    CABasicAnimation *strokeAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    strokeAnimation.beginTime = CACurrentMediaTime() + delay;
    strokeAnimation.duration = 0.3;
    strokeAnimation.fromValue = @0.0;
    strokeAnimation.toValue = @1.0;
    strokeAnimation.fillMode = kCAFillModeBoth;
    [self.arrowLineLayer addAnimation:strokeAnimation forKey:@"stroke"];
    
    delay += strokeAnimation.duration;
    CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.beginTime = CACurrentMediaTime() + delay;
    opacityAnimation.duration = 0.1;
    opacityAnimation.fromValue = @0.0;
    opacityAnimation.toValue = @1.0;
    opacityAnimation.fillMode = kCAFillModeBoth;
    [self.arrowTipLayer addAnimation:opacityAnimation forKey:@"opacity"];
}

- (void)addPoint:(CGPoint)point fromPreviousPoint:(CGPoint)previousPoint toNextPoint:(CGPoint)nextPoint withRadius:(CGFloat)radius toBezierPath:(UIBezierPath *)bezierPath {
    CGPoint startDelta = CGPointMake(previousPoint.x - point.x, previousPoint.y - point.y);
    CGPoint endDelta = CGPointMake(nextPoint.x - point.x, nextPoint.y - point.y);
    CGFloat startAngle = atan2f(-startDelta.y, startDelta.x);
    CGFloat endAngle = atan2f(-endDelta.y, endDelta.x);
    CGFloat midAngle = (startAngle - endAngle) / 2.0;
    CGFloat distance = radius / sinf(midAngle);
    CGPoint offset = CGPointMake(distance * cosf(midAngle), distance * sinf(midAngle));
    point = CGPointMake(point.x + offset.x, point.y - offset.y);
    
    CGFloat perpendicular = M_PI / 2.0;
    startAngle += perpendicular;
    endAngle += perpendicular;
    
    [bezierPath addArcWithCenter:point radius:radius startAngle:startAngle endAngle:endAngle clockwise:NO];
}

@end
