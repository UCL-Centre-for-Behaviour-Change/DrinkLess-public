//
//  PXAllStatistics.h
//  drinkless
//
//  Created by Edward Warrender on 06/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>
#import "PXWeekSummary.h"

typedef NS_ENUM(NSInteger, PXConsumptionType) {
    PXConsumptionTypeUnits,
    PXConsumptionTypeAlcoholFreeDays,
    PXConsumptionTypeCalories,
    PXConsumptionTypeSpending,
    PXConsumptionTypeMoodScore,
    PXConsumptionTypeGoals,
    PXConsumptionTypeGameResults
    // @TODO: We might need to make separate ones for ht PXBarPlot. Basically I thikn these are used in places where separate types should be.
};


//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////

@interface PXAllStatistics : NSObject

@property (strong, nonatomic) NSArray *weeklySummaries;
@property (strong, nonatomic) NSArray *plotData;
@property (strong, nonatomic, readonly) NSDictionary *maxValues;
@property (weak, nonatomic, readonly) PXWeekSummary *thisWeekSummary;
@property (weak, nonatomic, readonly) PXWeekSummary *lastWeekSummary;
@property (nonatomic, readonly) CGFloat allUnits;
@property (nonatomic, readonly) CGFloat allAlcFree;
@property (nonatomic, readonly) CGFloat allCalories;
@property (nonatomic, readonly) CGFloat allSpending;





//- (void)recalculate;

@end
