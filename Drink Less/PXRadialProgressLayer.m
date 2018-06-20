//
//  PXRadialProgressLayer.m
//  drinkless
//
//  Created by Edward Warrender on 03/03/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXRadialProgressLayer.h"

static CGFloat const PXStartAngle = -M_PI_2;
static CGFloat const PXStrokeWidth = 2.0;

@implementation PXRadialProgressLayer

- (id)init {
    self = [super init];
    if (self) {
        self.fillColor = [UIColor grayColor].CGColor;
        self.strokeColor = [UIColor clearColor].CGColor;
        self.rasterizationScale = [UIScreen mainScreen].scale;
        self.shouldRasterize = YES;
    }
    return self;
}

- (void)setProgress:(CGFloat)progress {
    progress = MAX(0.0, progress);
    progress = MIN(1.0, progress);
    _progress = progress;
    
    [self layoutIfNeeded];
    CGFloat diameter = MIN(self.bounds.size.width, self.bounds.size.height);
    CGFloat radius = diameter / 2.0;
    
    CGFloat strokeOffet = PXStrokeWidth * 0.5;
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(strokeOffet, strokeOffet, diameter - PXStrokeWidth, diameter - PXStrokeWidth)];
    CGPathRef path = CGPathCreateCopyByStrokingPath(bezierPath.CGPath, nil, PXStrokeWidth, bezierPath.lineCapStyle, bezierPath.lineJoinStyle, bezierPath.miterLimit);
    bezierPath = [[UIBezierPath bezierPathWithCGPath:path] bezierPathByReversingPath];
    CGPathRelease(path);
    
    CGPoint center = CGPointMake(radius, radius);
    CGFloat angle = (M_PI * 2.0) * progress;
    UIBezierPath *arcPath = [UIBezierPath bezierPathWithArcCenter:center radius:radius - strokeOffet startAngle:PXStartAngle endAngle:PXStartAngle + angle clockwise:YES];
    [arcPath addLineToPoint:center];
    [arcPath closePath];
    [bezierPath appendPath:arcPath];
    self.path = bezierPath.CGPath;
}

@end
