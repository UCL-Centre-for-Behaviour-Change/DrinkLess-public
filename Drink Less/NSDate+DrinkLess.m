//
//  NSDate+DrinkLess.m
//  Drink Less
//
//  Created by Chris on 15/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "NSDate+DrinkLess.h"
#import "PXDebug.h"

@implementation NSDate (DrinkLess)

+ (NSDate *)strictDateFromToday {
    return [NSDate strictDateFromDate:[NSDate date]];
}

+ (NSDate *)strictDateFromDate:(NSDate *)date {
    NSUInteger flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents *components = [[NSCalendar currentCalendar] components:flags fromDate:date];
    NSString *stringDate = [NSString stringWithFormat:@"%ld/%ld/%ld", (long)components.day, (long)components.month, (long)components.year];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    formatter.dateFormat = @"dd/MM/yyyy";
    return [formatter dateFromString:stringDate];
}

+ (NSDate *)nextDayFromDate:(NSDate *)date {
    return [NSDate changeDate:date byDays:1];
}

+ (NSDate *)previousDayFromDate:(NSDate *)date {
    return [NSDate changeDate:date byDays:-1];
}

+ (NSDate *)changeDate:(NSDate *)date byDays:(NSInteger)daysCount {
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init] ;
    dayComponent.day = daysCount;
    
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    return [theCalendar dateByAddingComponents:dayComponent toDate:date options:0];
}

+ (NSString *)strictDateStringFromDate:(NSDate *)date {
    NSUInteger flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents *components = [[NSCalendar currentCalendar] components:flags fromDate:date];
    return [NSString stringWithFormat:@"%02li/%02li/%02li", (long)components.day, (long)components.month, (long)components.year];
}

+ (BOOL)isDate:(NSDate *)date1 sameDayAsDate:(NSDate *)date2 {
    if (!date2) {
        return NO;
    }
    NSUInteger flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents *date1Components = [[NSCalendar currentCalendar] components:flags fromDate:date1];
    NSDateComponents *date2Components = [[NSCalendar currentCalendar] components:flags fromDate:date2];
    
    if (date1Components.day == date2Components.day &&
        date1Components.month == date2Components.month &&
        date1Components.year == date2Components.year) {
        return YES;
    }
    return NO;
}

+ (NSDate *)dateFromComponentsString:(NSString *)string {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    formatter.dateFormat = @"dd/MM/yyyy";
    return [formatter dateFromString:string];
}

+ (NSInteger)daysBetweenDate:(NSDate *)fromDateTime andDate:(NSDate *)toDateTime {
    NSDate *fromDate;
    NSDate *toDate;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate interval:nil forDate:fromDateTime];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate interval:nil forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSCalendarUnitDay
                                               fromDate:fromDate toDate:toDate options:0];
    return difference.day;
}

+ (NSDate *)dateFromComponentDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year {
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.day = day;
    dateComponents.month = month;
    dateComponents.year = year;
    return [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
}

- (NSDate *)nextOccurrenceOfTimeInDate {
    NSDate *now = [NSDate date];
    NSDateComponents *components = [self getComponents];
    NSDateComponents *nowComponents = [now getComponents];
    NSDateComponents *combinedComponents = [[NSDateComponents alloc] init];
    combinedComponents.year = nowComponents.year;
    combinedComponents.month = nowComponents.month;
    combinedComponents.day = nowComponents.day;
    combinedComponents.hour = components.hour;
    combinedComponents.minute = components.minute;

    NSDate *possibleFireDate = [[NSCalendar currentCalendar] dateFromComponents:combinedComponents];
    if ([possibleFireDate timeIntervalSinceDate:now] < 0) { // date is in the past
        possibleFireDate = [possibleFireDate dateByAddingTimeInterval:60*60*24];
    }
    return possibleFireDate;
}

- (NSDateComponents *)getComponents {
    NSUInteger flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay |NSCalendarUnitHour | NSCalendarUnitMinute;
    NSDateComponents *components = [[NSCalendar currentCalendar] components:flags fromDate:self];
    return components;
}

+ (NSDate *)yesterday {
    return [NSDate previousDayFromDate:[NSDate strictDateFromToday]];
}

+ (NSDate *)tomorrow {
    return [NSDate nextDayFromDate:[NSDate strictDateFromToday]];
}

+ (NSDate *)startOfThisWeek {
    return [[NSDate date] startOfWeek];
}

- (NSDate *)startOfWeek {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    calendar.firstWeekday = 2; // Monday
    NSDate *startDate;
    [calendar rangeOfUnit:NSCalendarUnitWeekOfYear startDate:&startDate interval:nil forDate:self];
    return startDate;
}

//---------------------------------------------------------------------

- (NSDate *)dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:(NSTimeZone *)thisDatesTimezone
{
    NSDateComponents *dateComps = [NSCalendar.currentCalendar componentsInTimeZone:thisDatesTimezone fromDate:self];
    NSDate *newDate = [NSDate dateFromComponentDay:dateComps.day  month:dateComps.month year:dateComps.year];//uses current calendar
    
    return newDate;
}

//---------------------------------------------------------------------

- (BOOL)dateWithTimeZone:(NSTimeZone *)thisDatesTimeZone fallsWithinCurrentCalendarDateRangeFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
    NSDate *dateInCurrentCalendar = [self dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:thisDatesTimeZone];
    
    if ([dateInCurrentCalendar compare:fromDate] != NSOrderedAscending ||
        [dateInCurrentCalendar compare:toDate] == NSOrderedAscending) {
        // note: the first conditional is boundary inclusive
        return NO;
    }
    
    return YES;
}

//---------------------------------------------------------------------

- (NSDate *)earliestWorldDateWithSameCalendarDateAsThisOne
{
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDateComponents *dc = [cal components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:self];
 
    const NSInteger MAX_TZ_OFFSET = 14 * 3600;
    NSInteger timeToSubtract = MAX_TZ_OFFSET - cal.timeZone.secondsFromGMT + (dc.hour * 3600) + (dc.minute * 60) + dc.second;  // minute/second should be zero in the context this is typically called from
    
    return [self dateByAddingTimeInterval:-timeToSubtract];
}

//---------------------------------------------------------------------

- (NSDate *)latestWorldDateWithSameCalendarDateAsThisOne
{
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDateComponents *dc = [cal components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:self];
    
    const NSInteger MIN_TZ_OFFSET = -14 * 3600;
    NSInteger timeToAdd = cal.timeZone.secondsFromGMT - MIN_TZ_OFFSET + ((24*3600) - (dc.hour * 3600) - (dc.minute * 60) - dc.second);  // minute/second should be zero in the context this is typically called from
    
    return [self dateByAddingTimeInterval:timeToAdd];
}

//---------------------------------------------------------------------

- (BOOL)isSameCalendarDateAs:(NSDate *)date
{
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSCalendarUnit units = (NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay);
    NSDateComponents *this = [cal components:units fromDate:self];
    NSDateComponents *that = [cal components:units fromDate:date];
    return this.year == that.year && this.month == that.month && this.day == that.day;
}

//---------------------------------------------------------------------

- (BOOL)isSameCalendarDateAs:(NSDate *)date withTimeZone:(NSTimeZone *)timezone
{
    NSDate *dateWithSameComponentsInCurrentCalendar = [date dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:timezone];
    
    return [self isSameCalendarDateAs:dateWithSameComponentsInCurrentCalendar];
}

//---------------------------------------------------------------------

- (NSString *)calendarDateStr
{
    return [NSDateFormatter localizedStringFromDate:self dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
}



@end
