//
//  PXCPTBarPlot.m
//  drinkless
//
//  Created by Hari Karam Singh on 14/04/2016.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXCPTBarPlot.h"

/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@interface CPTBarPlot()

// Expose superclass methods
-(void)drawBarInContext:(CGContextRef)context recordIndex:(NSUInteger)idx;
-(BOOL)barAtRecordIndex:(NSUInteger)idx basePoint:(CGPoint *)basePoint tipPoint:(CGPoint *)tipPoint;
-(BOOL)barIsVisibleWithBasePoint:(CGPoint)basePoint;
-(CGFloat)lengthInView:(NSDecimal)decimalLength;

@end

/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////


@implementation PXCPTBarPlot

-(void)drawBarInContext:(CGContextRef)context recordIndex:(NSUInteger)idx
{
    // Get base and tip points
    CGPoint basePoint, tipPoint;
    BOOL barExists = [self barAtRecordIndex:idx basePoint:&basePoint tipPoint:&tipPoint];
    
    // Just copying superclass here
    if ( !barExists ) {
        return;
    }
    if ( ![self barIsVisibleWithBasePoint:basePoint] ) {
        return;
    }
    
    double barValue = [self cachedDoubleForField:CPTBarPlotFieldBarTip recordIndex:idx];
    
    
    // Check the barValue. Use superclass if non zero. Otherwise do the icon
    if (barValue > 0 || self.isGameBarPlot) {
        [super drawBarInContext:context recordIndex:idx];
    } else {
        
        const CGFloat MAX_W = 50;
        const CGFloat MARGIN = 5;
        CGFloat barWidthLength = [self lengthInView:self.barWidth.decimalValue];
        
        UIImage *icon = [UIImage imageNamed:@"icon_alcohol_free"];
        
        //    l.frame = plot.bounds;
        CGFloat renderW = MIN(barWidthLength, MAX_W);
        CGFloat renderH = icon.size.height / icon.size.width * renderW;
        CGRect f = CGRectMake(basePoint.x - renderW/2.0, MARGIN, renderW, renderH);
//        CALayer *l = [CALayer layer];
//        l.frame = f;
//        l.contents = (id)icon.CGImage;
//        l.transform = CATransform3DMakeRotation(M_PI, 0, 0, 1);
//        
//        [self addSublayer:l];
        CGContextDrawImage(context, f, icon.CGImage);
    }
}

@end
