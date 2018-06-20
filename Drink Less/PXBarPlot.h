//
//  PXBarPlot.h
//  drinkless
//
//  Created by Edward Warrender on 02/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXPlot.h"

@class CPTGraphHostingView;

extern NSString *const PXDateKey;
extern NSString *const PXSpecialDateKey;
extern NSString *const PXPlotIdentifier;

typedef NS_ENUM(NSInteger, PXAxisTypeX) {
    PXAxisTypeNumber,
    PXAxisTypeTitle,
    PXAxisTypeDate
};

@protocol PXBarPlotDelegate;

@interface PXBarPlot : PXPlot

@property (strong, nonatomic) NSArray *plots;
@property (strong, nonatomic) NSString *xAxisDateFormat;
@property (strong, nonatomic) NSString *xAxisSpecialDateFormat;
@property (weak, nonatomic) id <PXBarPlotDelegate> delegate;
@property (assign, nonatomic) BOOL isGameBarPlot;

- (void)setXTitle:(NSString *)xTitle yTitle:(NSString *)yTitle xKey:(NSObject *)xKey yKey:(NSObject *)yKey minYValue:(CGFloat)minYValue maxYValue:(CGFloat)maxYValue goalValue:(CGFloat)goalValue displayAsPercentage:(BOOL)displayAsPercentage axisTypeX:(PXAxisTypeX)axisTypeX showLegend:(BOOL)showLegend;

@end

@protocol PXBarPlotDelegate <NSObject>
@optional

- (void)barPlot:(PXBarPlot *)barPlot didSelectItemAtIndex:(NSInteger)index;

@end
