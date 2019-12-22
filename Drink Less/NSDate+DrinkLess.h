//
//  NSDate+DrinkLess.h
//  Drink Less
//
//  Created by Chris on 15/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

@interface NSDate (DrinkLess)

+ (NSDate *)strictDateFromToday;
+ (NSDate *)strictDateFromDate:(NSDate *)date;
+ (NSDate *)nextDayFromDate:(NSDate *)date;
+ (NSDate *)previousDayFromDate:(NSDate *)date;
+ (NSDate *)changeDate:(NSDate *)date byDays:(NSInteger)daysCount;
+ (NSString *)strictDateStringFromDate:(NSDate *)date;
+ (BOOL)isDate:(NSDate *)date1 sameDayAsDate:(NSDate *)date2;
+ (NSDate *)dateFromComponentsString:(NSString *)string;
+ (NSInteger)daysBetweenDate:(NSDate *)fromDateTime andDate:(NSDate *)toDateTime;
+ (NSDate *)dateFromComponentDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year;
- (NSDate *)nextOccurrenceOfTimeInDate;
+ (NSDate *)yesterday;
+ (NSDate *)tomorrow;
+ (NSDate *)startOfThisWeek;
- (NSDate *)startOfWeek;

/** Convert to the NSDate in the current calendar such that it will have matching date components to this one */
- (NSDate *)dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:(NSTimeZone *)thisDatesTimezone;
- (NSDate *)dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezoneIncludingTime:(NSTimeZone *)thisDatesTimezone;

/** Assumes from/to Date are hh:mm = 00:00. fromDate bounary is inclusive, toDate exclusive */
- (BOOL)dateWithTimeZone:(NSTimeZone *)thisDatesTimeZone fallsWithinCurrentCalendarDateRangeFrom:(NSDate *)fromDate to:(NSDate *)toDate;

/** Calculates the earliest/lastest possible time in the world in any time zone that will have the same calendar date as this one. Actually, errs on the side of caution assuming ±14 hours for time zone span. Assumes this date is from the current calendar */
- (NSDate *)earliestWorldDateWithSameCalendarDateAsThisOne;
- (NSDate *)latestWorldDateWithSameCalendarDateAsThisOne;

/** Returns true if d-m-y is the same */
- (BOOL)isSameCalendarDateAs:(NSDate *)date;
- (BOOL)isSameCalendarDateAs:(NSDate *)date withTimeZone:(NSTimeZone *)timezone;

// Debug method
- (NSString *)calendarDateStr;

#if DEBUG
/// Override to allow for our debugging hack
- (NSTimeInterval)timeIntervalSinceNow;
#endif



@end
