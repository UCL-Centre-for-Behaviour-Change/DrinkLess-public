//
//  PXDrinkRecord+Extras.h
//  drinkless
//
//  Created by Edward Warrender on 28/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXDrinkRecord.h"

@class PXDrinkServing, PXDrinkType, PXDrinkAddition, PFObject;

@interface PXDrinkRecord (Extras)

/** USE WITH CAUTION. Default to using the CalendarDate method below. */
+ (NSArray *)fetchDrinkRecordsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate context:(NSManagedObjectContext *)context;

+ (NSUInteger)fetchCountOfDrinkingDaysFromCalendarDate:(NSDate *)fromDate toCalendarDate:(NSDate *)toDate context:(NSManagedObjectContext *)context;

// Finds all records whose calendar comps in their respective tz's fall within those of the range defined by the from/ToDates rendered to components on the current calendar's tz (@see README.md)
+ (NSArray *)fetchDrinkRecordsFromCalendarDate:(NSDate *)fromDate toCalendarDate:(NSDate *)toDate context:(NSManagedObjectContext *)context;

/** A carefully taylored FetchRequest that includes all objects that fall in that calendar date, TZ normalised. Called when we need to use NSFetchedResultsController to keep track of records
 @TODO: Note, this is a bit of a hack. Ideally we need to rewrite the respective VCs using it to not use NSFetchedResultsController as we need to handle it a bit more specifically
 */
+ (NSFetchRequest *)fetchRequestFromCalendarDate:(NSDate *)fromDate toCalendarDate:(NSDate *)toDate context:(NSManagedObjectContext *)context;
+ (NSFetchRequest *)fetchRequestForCalendarDate:(NSDate *)date context:(NSManagedObjectContext *)context;
+ (NSPredicate *)fetchRequestPredicateFromCalendarDate:(NSDate *)fromDate toCalendarDate:(NSDate *)toDate context:(NSManagedObjectContext *)context;
+ (NSPredicate *)fetchRequestPredicateForCalendarDate:(NSDate *)date context:(NSManagedObjectContext *)context;


@property (nonatomic, retain, readonly) PXDrinkServing * serving;
@property (nonatomic, retain, readonly) PXDrinkAddition * addition;
@property (nonatomic, retain, readonly) PXDrinkType * type;

- (PXDrinkRecord *)copyDrinkRecordIntoContext:(NSManagedObjectContext *)context;
- (void)saveToParse;
- (void)deleteFromParse;

@end
