//
//  PXWeekSummary.m
//  drinkless
//
//  Created by Edward Warrender on 14/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXWeekSummary.h"
#import "PXDrinkRecord.h"
#import "NSTimeZone+DrinkLess.h"

@implementation PXWeekSummary

- (instancetype)initWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate drinkRecords:(NSArray *)drinkRecords alcoholFreeDays:(NSInteger)alcoholFreeDays {
    if (self == [super init]) {
        _startDate = startDate;
        _endDate = endDate;
        _lastDate = [endDate dateByAddingTimeInterval:-0.001];
        _drinkRecords = drinkRecords;
        _alcoholFreeDays = alcoholFreeDays;
        _totalUnits = _totalCalories = _totalSpending = 0.0;

        for (PXDrinkRecord *drinkRecord in drinkRecords) {
            
            _totalUnits += drinkRecord.totalUnits.floatValue;
            _totalCalories += drinkRecord.totalCalories.floatValue;
            _totalSpending += drinkRecord.totalSpending.floatValue;
        }
    }
    return self;
}

@end
