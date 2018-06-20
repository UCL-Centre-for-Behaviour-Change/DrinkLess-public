//
//  PXPlot.h
//  drinkless
//
//  Created by Edward Warrender on 01/05/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>
#import "CorePlot-CocoaTouch.h"

@interface PXPlot : NSObject

extern NSString *const PXTitleKey;
extern NSString *const PXColorKey;

- (instancetype)initWithHostingView:(CPTGraphHostingView *)hostingView;

@property (strong, nonatomic) NSArray *plotData;
@property (weak, nonatomic) CPTGraphHostingView *hostingView;
@property (strong, nonatomic) CPTGraph *graph;
@property (nonatomic) CGFloat paddingBottomOffset;
@property (nonatomic, getter = isLegendHidden) BOOL legendHidden;

- (void)setupGraph;
- (void)setupLegend;
- (void)updateLegendWithCount:(NSInteger)count;

@end
