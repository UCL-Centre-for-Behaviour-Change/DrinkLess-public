//
//  PXDashboardTableView.m
//  drinkless
//
//  Created by Edward Warrender on 01/07/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXDashboardTableView.h"
#import "CorePlot-CocoaTouch.h"

@implementation PXDashboardTableView

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    if ([view isKindOfClass:[CPTGraphHostingView class]]) {
        return NO;
    }
    return [super touchesShouldCancelInContentView:view];;
}

@end
