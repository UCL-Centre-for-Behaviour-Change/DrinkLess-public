//
//  PXAlcoholFreeRecord+Extras.h
//  drinkless
//
//  Created by Edward Warrender on 12/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXAlcoholFreeRecord.h"

@interface PXAlcoholFreeRecord (Extras)

/**
 USE WITH CAUTION. Default to using the CalendarDate method below. Queries for the raw date range as stored in the records' date property */
//+ (NSArray *)fetchFreeRecordsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate context:(NSManagedObjectContext *)context;

/** Looks for records in all time zones that have the same date comps as the given date in the current calendar */
+ (NSArray *)fetchFreeRecordsForCalendarDate:(NSDate *)date context:(NSManagedObjectContext *)context;

/** Looks for records in all time zones that have the same date comps as the given date range in the current calendar. toDate is an exclusive bounds */
+ (NSArray *)fetchFreeRecordsFromCalendarDate:(NSDate *)fromDate toCalendarDate:(NSDate *)toDate context:(NSManagedObjectContext *)context;

/** Also stores the timezone of the current calendar */
+ (void)setFreeDay:(BOOL)freeDay date:(NSDate *)date context:(NSManagedObjectContext *)context;
/** Also stores the timezone of the current calendar */
+ (void)setFreeDay:(BOOL)freeDay fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate context:(NSManagedObjectContext *)context;

- (void)saveToParse;
- (void)deleteFromParse;

@end
