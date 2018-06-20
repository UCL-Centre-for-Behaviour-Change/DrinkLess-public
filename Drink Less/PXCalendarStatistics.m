//
//  PXCalendarStatistics.m
//  drinkless
//
//  Created by Edward Warrender on 05/11/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXCalendarStatistics.h"
#import "PXCoreDataManager.h"
#import "PXDrinkRecord+Extras.h"
#import "PXAlcoholFreeRecord+Extras.h"
#import "PXIntroManager.h"
#import "NSDate+DrinkLess.h"
#import "NSTimeZone+DrinkLess.h"
#import "PXDebug.h"

@interface PXCalendarStatistics ()

@property (strong, nonatomic) NSDictionary *days;

@end

@implementation PXCalendarStatistics

+ (instancetype)calculateFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {
    NSManagedObjectContext *context = [PXCoreDataManager sharedManager].managedObjectContext;
    NSMutableDictionary *calendarDaysStatuses = [NSMutableDictionary dictionary];
    BOOL isFemale = [PXIntroManager sharedManager].gender.boolValue;
    CGFloat unitsLimit = isFemale ? 6 : 6;
    NSMutableDictionary *datesTally = NSMutableDictionary.dictionary;
    
    NSArray *drinkRecords = [PXDrinkRecord fetchDrinkRecordsFromCalendarDate:fromDate toCalendarDate:toDate context:context];
    [drinkRecords enumerateObjectsUsingBlock:^(PXDrinkRecord *drinkRecord, NSUInteger idx, BOOL *stop) {
        
        // Get the "calendar date" for the drink record wrt to it's timezone (@see README.md)
        // @see README.md
        NSTimeZone *recTimezone = [NSTimeZone timeZoneForDrinkRecord:drinkRecord];
        NSDate *dateInCurrentCalendar = [drinkRecord.date dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:recTimezone];
        
//        logd(@"Record: Date=%@, TZ=%.2f, Calendar Range=%@...%@", [NSDateFormatter localizedStringFromDate:drinkRecord.date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle],
//             (CGFloat)recTimezone.secondsFromGMT/3600.0, [NSDateFormatter localizedStringFromDate:fromDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle], [NSDateFormatter localizedStringFromDate:toDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle]);
//        
        
        // Get previous values for that date
        CGFloat totalUnits = 0;
        NSNumber *t = datesTally[dateInCurrentCalendar];
        if (t) {
            totalUnits += t.floatValue;
        }
        totalUnits += drinkRecord.totalUnits.floatValue;
        // Don't record if zero, as later code will get confused
        if (totalUnits > 0) {
            datesTally[dateInCurrentCalendar] = @(totalUnits);
        }
    }];
    
    // All done tally. Now convert to PXDayStatus
    [datesTally enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
     
        NSDate *date = (NSDate *)key;
        NSNumber *tallyNum = (NSNumber *)obj;
        CGFloat unitsDrank = tallyNum.floatValue;
        
        // Skip 0 (shouldnt be but jic)
        if (unitsDrank == 0) {
            return;
        }
        
        PXDayStatus status = unitsDrank > unitsLimit ? PXDayStatusHeavyDrinking : PXDayStatusDrank;
        
        calendarDaysStatuses[date] = @(status);
    }];
    
    // ALCOHOL FREE DAYS
    NSArray *freeRecords = [PXAlcoholFreeRecord fetchFreeRecordsFromCalendarDate:fromDate toCalendarDate:toDate context:context];
    for (PXAlcoholFreeRecord *record in freeRecords) {
        // Get the "calendar date" for the drink record wrt to it's timezone (@see README.md)
        NSTimeZone *recTimezone = [NSTimeZone timeZoneForAlcoholFreeRecord:record];
        NSDate *dateInCurrentCalendar = [record.date dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:recTimezone];
        
        calendarDaysStatuses[dateInCurrentCalendar] = @(PXDayStatusAlcoholFree);
    }
    
    PXCalendarStatistics *calendarStatistics = [[self alloc] init];
    calendarStatistics.days = calendarDaysStatuses.copy;
    return calendarStatistics;
}

//---------------------------------------------------------------------

- (PXDayStatus)statusForDate:(NSDate *)date {
    NSNumber *number = self.days[date];
    if (number) {
        return number.integerValue;
    }
    return PXDayStatusNoRecords;
}

@end
