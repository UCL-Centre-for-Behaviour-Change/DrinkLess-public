//
//  PXCalendarStatistics.h
//  drinkless
//
//  Created by Edward Warrender on 05/11/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PXDayStatus) {
    PXDayStatusNoRecords,
    PXDayStatusAlcoholFree,
    PXDayStatusDrank,
    PXDayStatusHeavyDrinking,
    PXDayStatusHasUpcomingPlans   // for dates in the future only
};

@interface PXCalendarStatistics : NSObject

/** IMPORTANT: fromDate and toDate are the Calendar days, NOT absolute times as NSDate is intended to represent. For a given date, we calculate the totals for that day as it was entered by the user. E.g. If they enter a drink at 11pm in London on Tuesday then fly to NY and enter another drink at 11pm (EST). It will still tally with Tuesday even when they return to London where it technically is Wednesday. @see README.md */
+ (instancetype)calculateFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;

/** This is the calendar time as well. E.g. if you want Feb 1, 2017 in NY, you pass a date instantiaed  */
- (PXDayStatus)statusForDate:(NSDate *)date;

@end
