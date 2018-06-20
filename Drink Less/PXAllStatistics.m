//
//  PXAllStatistics.m
//  drinkless
//
//  Created by Edward Warrender on 06/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXAllStatistics.h"
#import "PXCoreDataManager.h"
#import "PXDrinkRecord+Extras.h"
#import "PXAlcoholFreeRecord+Extras.h"
#import "PXBarPlot.h"
#import "NSTimeZone+DrinkLess.h"

@implementation PXAllStatistics

- (instancetype)init {
    self = [super init];
    if (self) {
        _weeklySummaries = [self calculateWeeklySummaries];
        _plotData = [self calculatePlotData];
    }
    return self;
}

#pragma mark - Calculations

- (NSMutableArray *)calculateWeeklySummaries {
    PXCoreDataManager *coreDataManager = [PXCoreDataManager sharedManager];
    NSManagedObjectContext *context = coreDataManager.managedObjectContext;
    
    NSDate *thisWeek = [NSDate startOfThisWeek];
    NSDate *firstDrinkDate = [self.class earliestDateForEntityWithName:@"PXDrinkRecord" context:context];
    NSDate *firstAlcoholFreeDate = [self.class earliestDateForEntityWithName:@"PXAlcoholFreeRecord" context:context];
    NSDate *referenceDate = [firstDrinkDate compare:firstAlcoholFreeDate] == NSOrderedAscending ? firstDrinkDate : firstAlcoholFreeDate;
    
    NSMutableArray *weeks = [NSMutableArray array];
    __block PXWeekSummary *previousWeekSummary;
    
    _allUnits = 0.0;
    _allCalories = 0.0;
    _allSpending = 0.0;
    _thisWeekSummary = nil;
    
    [self.class enumerateWeeksFromDate:referenceDate block:^(NSDate *fromDate, NSDate *toDate) {
        
        // We want to get every record that could possibly fall on the current calendar date range. We'll need to check them with their time zone later. @see README.md
        NSMutableArray *drinkRecords = [PXDrinkRecord fetchDrinkRecordsFromCalendarDate:fromDate toCalendarDate:toDate context:context].mutableCopy;
        NSMutableArray *alcoholFreeRecords = [PXAlcoholFreeRecord fetchFreeRecordsFromCalendarDate:fromDate toCalendarDate:toDate context:context].mutableCopy;
        
        // We want the query dates here as they represent the calendar dates in the current calendar. BUT the records should cover the tz safety range
        PXWeekSummary *weekSummary = [[PXWeekSummary alloc] initWithStartDate:fromDate endDate:toDate drinkRecords:drinkRecords alcoholFreeDays:alcoholFreeRecords.count];
        weekSummary.previousWeekSummary = previousWeekSummary;
        previousWeekSummary = weekSummary;
        [weeks addObject:weekSummary];
        
        _allUnits += weekSummary.totalUnits;
        _allCalories += weekSummary.totalCalories;
        _allSpending += weekSummary.totalSpending;
        
        if ([fromDate isEqualToDate:thisWeek]) {
            _thisWeekSummary = weekSummary;
        }
    }];
    return weeks;
}

+ (NSDate *)earliestDateForEntityWithName:(NSString *)entityName context:(NSManagedObjectContext *)context {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    fetchRequest.resultType = NSDictionaryResultType;
    NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:@"date"];
    NSExpression *minExpression = [NSExpression expressionForFunction:@"min:" arguments:@[keyPathExpression]];
    NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
    expressionDescription.name = @"date";
    expressionDescription.expression = minExpression;
    expressionDescription.expressionResultType = NSDateAttributeType;
    fetchRequest.propertiesToFetch = @[expressionDescription];
    
    NSArray *results = [context executeFetchRequest:fetchRequest error:NULL];
    NSDate *date = results.firstObject[@"date"];
    if (!date) {
        date = [NSDate strictDateFromToday];
    }
    return date;
}

+ (void)enumerateWeeksFromDate:(NSDate *)referenceDate block:(void (^)(NSDate *fromDate, NSDate *toDate))block {
    NSDate *fromDate = [referenceDate startOfWeek];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.weekOfYear = 1;
    
    BOOL stop = NO;
    while (!stop) {
        NSDate *toDate = [calendar dateByAddingComponents:dateComponents toDate:fromDate options:0];
        stop = (toDate.timeIntervalSinceNow >= 0.0);
        if (block) {
            block(fromDate, toDate);
        }
        fromDate = toDate;
    }
}

- (NSMutableArray *)calculatePlotData {
    NSMutableArray *plotData = [NSMutableArray array];
    CGFloat maxUnits = 0.0;
    CGFloat maxCalories = 0.0;
    CGFloat maxSpending = 0.0;
    
    NSUInteger plotId = 0;
    for (PXWeekSummary *weekSummary in self.weeklySummaries) {
        CGFloat totalUnits = weekSummary.totalUnits;
        CGFloat totalCalories = weekSummary.totalCalories;
        CGFloat totalSpending = weekSummary.totalSpending;
        
        if (totalUnits > maxUnits) maxUnits = totalUnits;
        if (totalCalories > maxCalories) maxCalories = totalCalories;
        if (totalSpending > maxSpending) maxSpending = totalSpending;
        
        NSDictionary *dictionary = @{PXPlotIdentifier: @(++plotId),
                                     PXDateKey: weekSummary.lastDate,
                                     @(PXConsumptionTypeUnits): @(totalUnits),
                                     @(PXConsumptionTypeCalories): @(totalCalories),
                                     @(PXConsumptionTypeSpending): @(totalSpending)};
        [plotData addObject:dictionary];
    }
    _maxValues = @{@(PXConsumptionTypeUnits): @(maxUnits),
                   @(PXConsumptionTypeCalories): @(maxCalories),
                   @(PXConsumptionTypeSpending): @(maxSpending)};
    return plotData;
}

@end
