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
typedef NS_ENUM(NSInteger, PXConsumptionType);

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
@property (assign, nonatomic) BOOL dontUseNoDrinksIcon; // TODO: Do this better...

// @deprecated
//- (void)setXTitle:(NSString *)xTitle yTitle:(NSString *)yTitle xKey:(NSObject *)xKey yKey:(NSObject *)yKey minYValue:(CGFloat)minYValue maxYValue:(CGFloat)maxYValue goalValue:(CGFloat)goalValue displayAsPercentage:(BOOL)displayAsPercentage axisTypeX:(PXAxisTypeX)axisTypeX showLegend:(BOOL)showLegend;

// @deprecated
- (void)setXTitle:(NSString *)xTitle yTitle:(NSString *)yTitle xKey:(NSObject *)xKey yKey:(NSObject *)yKey minYValue:(CGFloat)minYValue maxYValue:(CGFloat)maxYValue goalValue:(CGFloat)goalValue displayAsPercentage:(BOOL)displayAsPercentage displayAsCurrency:(BOOL)displayAsCurrency axisTypeX:(PXAxisTypeX)axisTypeX showLegend:(BOOL)showLegend;

// The new designated
- (void)setXTitle:(NSString *)xTitle yTitle:(NSString *)yTitle xKey:(NSObject *)xKey yKey:(NSObject *)yKey minYValue:(CGFloat)minYValue maxYValue:(CGFloat)maxYValue goalValue:(CGFloat)goalValue consumptionType:(PXConsumptionType)consumptionType showLegend:(BOOL)showLegend;

@end


@protocol PXBarPlotDelegate <NSObject>
@optional

- (void)barPlot:(PXBarPlot *)barPlot didSelectItemAtIndex:(NSInteger)index;

@end
