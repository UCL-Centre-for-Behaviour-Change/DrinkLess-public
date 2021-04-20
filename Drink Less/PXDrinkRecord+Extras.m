//
//  PXDrinkRecord+Extras.m
//  drinkless
//
//  Created by Edward Warrender on 28/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXDrinkRecord+Extras.h"
#import "PXDrink.h"
#import "PXDrinkServing.h"
#import "PXDrinkType.h"
#import "NSManagedObject+PXFindByID.h"
#import "PXDrinkCalculator.h"
#import "NSTimeZone+DrinkLess.h"
#import "NSDateComponents+DrinkLess.h"
#import "drinkless-Swift.h"
#import "PXDebug.h"

@implementation PXDrinkRecord (Extras)

+ (NSArray *)fetchDrinkRecordsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate context:(NSManagedObjectContext *)context {
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PXDrinkRecord"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"date >= %@ && date < %@", fromDate, toDate];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
    
    return [context executeFetchRequest:fetchRequest error:nil];
}

//---------------------------------------------------------------------

+ (NSArray *)fetchDrinkRecordsFromCalendarDate:(NSDate *)fromDate toCalendarDate:(NSDate *)toDate context:(NSManagedObjectContext *)context
{
    NSDate *worldFromDate = [fromDate earliestWorldDateWithSameCalendarDateAsThisOne];
    NSDate *worldToDate = [toDate latestWorldDateWithSameCalendarDateAsThisOne];
    
    NSArray<PXDrinkRecord *> *records = [self fetchDrinkRecordsFromDate:worldFromDate toDate:worldToDate context:context];
    
    logd(@"Fetched %lu records in Calendar Dates [%@, %@) ==> Actual [%@, %@)", records.count, fromDate.calendarDateStr, toDate.calendarDateStr, worldFromDate.calendarDateStr, worldToDate.calendarDateStr);
    
    NSMutableArray<PXDrinkRecord *> *recordsInRange = [NSMutableArray array];
    
    NSCalendar *calendar = NSCalendar.currentCalendar;
    NSCalendarUnit units = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay;
    NSDateComponents *fromDateComps = [calendar components:units fromDate:fromDate];
    NSDateComponents *toDateComps = [calendar components:units fromDate:toDate];
                                       
    for (PXDrinkRecord *record in records) {
        
        NSDateComponents *recDateComps = [calendar componentsInTimeZone:[NSTimeZone timeZoneForDrinkRecord:record] fromDate:record.date];
        
        // Compare [,)
        if ([recDateComps compare:fromDateComps] != NSOrderedAscending &&
            [recDateComps compare:toDateComps] == NSOrderedAscending) {
            [recordsInRange addObject:record];
        } else {
            logd(@"Excluding record with Date/TZ = %@, %.2f (%@)", record.date, [NSTimeZone timeZoneForDrinkRecord:record].secondsFromGMT/3600., record.timezone);
        }
    }
    
    return recordsInRange;
}

//---------------------------------------------------------------------

+ (NSUInteger)fetchCountOfDrinkingDaysFromCalendarDate:(NSDate *)fromDate toCalendarDate:(NSDate *)toDate context:(NSManagedObjectContext *)context
{
    NSArray<PXDrinkRecord *> *records = [self fetchDrinkRecordsFromCalendarDate:fromDate toCalendarDate:toDate context:context];

    // Tally the calendar dates
    NSMutableSet <NSDateComponents *> *calDates = [NSMutableSet set];
    NSCalendar *calendar = NSCalendar.currentCalendar;
    for (PXDrinkRecord *record in records) {
        NSTimeZone *tz = [NSTimeZone timeZoneWithName:record.timezone];
        NSDateComponents *recDateComps = [calendar componentsInTimeZone:tz fromDate:record.date];
        
        // Check for an existing entry and add if none
        BOOL missing = YES;
        for (NSDateComponents *dc in calDates) {
            if ([dc compare:recDateComps] == NSOrderedSame) {
                missing = NO;
                break;
            }
        }
        if (missing) {
            [calDates addObject:recDateComps];
        }
    }
    
    return calDates.count;
}

//---------------------------------------------------------------------

+ (NSPredicate *)fetchRequestPredicateFromCalendarDate:(NSDate *)fromDate toCalendarDate:(NSDate *)toDate context:(NSManagedObjectContext *)context
{
//    // First get all the potential records in that timeframe
//    NSDate *worldFromDate = [fromDate earliestWorldDateWithSameCalendarDateAsThisOne];
//    NSDate *worldToDate = [toDate latestWorldDateWithSameCalendarDateAsThisOne];
//    NSArray *possibleRecords = [self fetchDrinkRecordsFromDate:worldFromDate toDate:worldToDate context:context];
    
    // Fetch the actual records that fall in that *calendar* date range
    NSArray *actualRecords = [self fetchDrinkRecordsFromCalendarDate:fromDate toCalendarDate:toDate context:context];
    
    // Now construct a fetch request grabbing them specifically
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF IN %@", actualRecords];
    
    return predicate;
}

//---------------------------------------------------------------------

+ (NSFetchRequest *)fetchRequestFromCalendarDate:(NSDate *)fromDate toCalendarDate:(NSDate *)toDate context:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"PXDrinkRecord" inManagedObjectContext:context];
    fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO]]; // this is a potential problem too but we'll let it go for now as it's minimal impact
    fetchRequest.predicate = [self fetchRequestPredicateFromCalendarDate:fromDate toCalendarDate:toDate context:context];
    return fetchRequest;
}

//---------------------------------------------------------------------

+ (NSPredicate *)fetchRequestPredicateForCalendarDate:(NSDate *)date context:(NSManagedObjectContext *)context
{
    NSDate *datePlus1 = [NSDate nextDayFromDate:date];
    return [self fetchRequestPredicateFromCalendarDate:date toCalendarDate:datePlus1 context:context];
}

//---------------------------------------------------------------------

+ (NSFetchRequest *)fetchRequestForCalendarDate:(NSDate *)date context:(NSManagedObjectContext *)context
{
    logd(@"-------------------------");
    // No block preds with CoreData :< :< :<
//    NSFetchRequest *fetchRequest = NSFetchRequest.new;
//    fetchRequest.entity = [NSEntityDescription entityForName:@"PXDrinkRecord" inManagedObjectContext:context];
//    fetchRequest.predicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
//
//        PXDrinkRecord *record = evaluatedObject;
//        NSCalendar *calendar = NSCalendar.currentCalendar;
//
//        NSDateComponents *recDateComps = [calendar componentsInTimeZone:[NSTimeZone timeZoneForDrinkRecord:record] fromDate:record.date];
//        NSDateComponents *thisDateComps = [calendar componentsInTimeZone:[NSTimeZone timeZoneForDrinkRecord:record] fromDate:date];
//
//        return (recDateComps.year == thisDateComps.year &&
//                recDateComps.month == thisDateComps.month &&
//                recDateComps.day == thisDateComps.day);
//    }];
//
//    return fetchRequest;
    
    NSDate *datePlus1 = [NSDate nextDayFromDate:date];
    return [self fetchRequestFromCalendarDate:date toCalendarDate:datePlus1 context:context];
}

//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////


- (PXDrinkServing *)serving {
    [self willAccessValueForKey:@"serving"];
    PXDrinkServing *serving = [[self primitiveValueForKey:@"servings"] firstObject];
    [self didAccessValueForKey:@"serving"];
    return serving;
}

- (PXDrinkAddition *)addition {
    [self willAccessValueForKey:@"addition"];
    PXDrinkAddition *addition = [[self primitiveValueForKey:@"additions"] firstObject];
    [self didAccessValueForKey:@"addition"];
    return addition;
}

- (PXDrinkType *)type {
    [self willAccessValueForKey:@"type"];
    PXDrinkType *type = [[self primitiveValueForKey:@"types"] firstObject];
    [self didAccessValueForKey:@"type"];
    return type;
}

- (NSString *)iconName {
    [self willAccessValueForKey:@"iconName"];
    NSMutableString *iconName = @"icon".mutableCopy;
    if (self.drink)   [iconName appendFormat:@"_d%@", self.drink.identifier.stringValue];
    if (self.type)    [iconName appendFormat:@"_t%@", self.type.identifier.stringValue];
    NSNumber *sId = self.serving.identifier.integerValue >= kPXDrinkServingCustomIdentifier ? @2 : self.serving.identifier; // The 2 icons are bigger so lets use those
    if (self.serving) [iconName appendFormat:@"_s%@", sId.stringValue];
    [self didAccessValueForKey:@"iconName"];
    return iconName;
}

- (NSNumber *)totalCalories {
    [self willAccessValueForKey:@"totalCalories"];
    CGFloat calories = PXCalories(self.drink.identifier.integerValue,
                                  self.typeID.integerValue,
                                  self.additionID.integerValue,
                                  (NSInteger)roundf(self.abv.floatValue),
                                  self.serving.millilitres.floatValue);
    NSNumber *totalCalories = @(calories * self.quantity.integerValue);
    [self didAccessValueForKey:@"totalCalories"];
    return totalCalories;
}

- (NSNumber *)totalUnits {
    [self willAccessValueForKey:@"totalUnits"];
    CGFloat units = (self.serving.millilitres.floatValue / 1000.0) * self.abv.floatValue;
    NSNumber *totalUnits = @(units * self.quantity.integerValue);
    [self didAccessValueForKey:@"totalUnits"];
    return totalUnits;
}

- (NSNumber *)totalSpending {
    [self willAccessValueForKey:@"totalSpending"];
    NSNumber *totalSpending = @(self.price.floatValue * self.quantity.integerValue);
    [self didAccessValueForKey:@"totalSpending"];
    return totalSpending;
}

- (PXDrinkRecord *)copyDrinkRecordIntoContext:(NSManagedObjectContext *)context {
    PXDrinkRecord *drinkRecord = (PXDrinkRecord *)[PXDrinkRecord createInContext:context];
    drinkRecord.drink = (PXDrink *)[context objectWithID:self.drink.objectID];
    drinkRecord.abv = self.abv;
    drinkRecord.price = self.price;
    drinkRecord.quantity = @1;
    drinkRecord.typeID = self.typeID;
    drinkRecord.additionID = self.additionID;
    drinkRecord.servingID = self.servingID;
    drinkRecord.parseObjectId = self.parseObjectId;
    drinkRecord.parseUpdated = self.parseUpdated;
    return drinkRecord;
}

#pragma mark - Parse

- (void)saveToServer {
    self.parseUpdated = @NO;
    NSError *error;
    
    // Grab a strong ref as it's deallocating sometimes (on ipod at least)
    NSManagedObjectContext *context = self.managedObjectContext;
    [self.managedObjectContext save:&error];
    if (error) {
        logd("ERROR: %@", error);
    }
    
    logd("before:: %@", self.managedObjectContext);
    
    NSMutableDictionary *params = NSMutableDictionary.dictionary;
    if (self.drink.name)    params[@"drink"]           = self.drink.name;
    if (self.type.name)     params[@"type"]            = self.type.name;
    if (self.serving.name)  params[@"serving"]         = self.serving.name;
    if (self.quantity)      params[@"quantity"]        = self.quantity;
    if (self.price)         params[@"price_per_drink"] = self.price;
    if (self.abv)           params[@"abv"]             = self.abv;
    if (self.totalCalories) params[@"totalCalories"]   = self.totalCalories;
    if (self.totalUnits)    params[@"totalUnits"]      = self.totalUnits;
    if (self.totalSpending) params[@"totalSpending"]   = self.totalSpending;
    if (self.favourite)     params[@"favourite"]       = self.favourite;
    if (self.date)          params[@"date"]            = self.date;
    if (self.timezone)      params[@"timezone"]        = self.timezone;
    
    [DataServer.shared saveDataObjectWithClassName:NSStringFromClass(self.class) objectId:self.parseObjectId isUser:YES params:params ensureSave:NO callback:^(BOOL succeeded, NSString *objectId, NSError *error) {
        
        if (succeeded) {
            // Weird crash when it faults and MOC has been deallocated. Detect and save
            PXDrinkRecord *this = self;
            if (this.managedObjectContext == nil) {
                this = [PXCoreDataManager.sharedManager.managedObjectContext objectWithID:self.objectID];
                logd("WARN: Saving faulted MO with dealloced MOC (crash prevented)");
            }
            this.parseObjectId = objectId.copy;
            this.parseUpdated = @YES;
            [this.managedObjectContext save:nil];
        }
    }];
}

- (void)deleteFromParse {
    if (self.parseObjectId) {
        [DataServer.shared deleteDataObject:NSStringFromClass(self.class) objectId:self.parseObjectId];
    }
}

@end
