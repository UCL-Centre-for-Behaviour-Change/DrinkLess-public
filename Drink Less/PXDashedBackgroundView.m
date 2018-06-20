//
//  PXDashedBackgroundView.m
//  drinkless
//
//  Created by Edward Warrender on 26/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXDashedBackgroundView.h"

@implementation PXDashedBackgroundView

- (id)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, self.backgroundColor.CGColor);
    CGContextFillRect(context, rect);
    CGContextSetFillColorWithColor(context, self.fillColor.CGColor);
    CGContextSetStrokeColorWithColor(context, self.strokeColor.CGColor);
    
    CGFloat halfLineWidth = self.lineWidth / 2.0;
    CGRect pathRect = CGRectInset(rect, halfLineWidth, halfLineWidth);
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:pathRect cornerRadius:5.0];
    [bezierPath fill];
    
    if (self.lineWidth > 0.0) {
        if (self.isDashed) {
            CGFloat dashLengths[] = {4.0, 2.0};
            [bezierPath setLineDash:dashLengths count:sizeof(dashLengths)/sizeof(CGFloat) phase:0.0];
        }
        bezierPath.lineWidth = self.lineWidth;
        [bezierPath stroke];
    }
}

@end
