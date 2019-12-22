//
//  PXAlcoholFreeRecord+Extras.m
//  drinkless
//
//  Created by Edward Warrender on 12/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXAlcoholFreeRecord+Extras.h"
#import "NSManagedObject+PXFindByID.h"
#import "PXDrinkRecord.h"
#import "PXDrinkRecord+Extras.h"
#import "PXStepGuide.h"
#import "NSTimeZone+DrinkLess.h"
#import "PXDebug.h"
#import "NSDateComponents+DrinkLess.h"
#import "NSDate+DrinkLess.h"
#import "drinkless-Swift.h"

@implementation PXAlcoholFreeRecord (Extras)

+ (NSFetchRequest *)alcoholFreeRecordFetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([self class])];
}

+ (NSArray *)_fetchFreeRecordsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate context:(NSManagedObjectContext *)context {
    NSFetchRequest *fetchRequest = [self alcoholFreeRecordFetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"date >= %@ && date < %@", fromDate, toDate];
    fetchRequest.resultType = NSManagedObjectResultType;
    return [context executeFetchRequest:fetchRequest error:nil];
}

//---------------------------------------------------------------------

+ (NSArray *)fetchFreeRecordsForCalendarDate:(NSDate *)date context:(NSManagedObjectContext *)context {
    
//    NSFetchRequest *fetchRequest = [self alcoholFreeRecordFetchRequest];
//    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"date == %@", date];
//    return [context executeFetchRequest:fetchRequest error:nil];
    NSDate *datePlus1 = [NSDate nextDayFromDate:date];
    return [self fetchFreeRecordsFromCalendarDate:date toCalendarDate:datePlus1 context:context];
}

//---------------------------------------------------------------------

+ (NSArray *)fetchFreeRecordsFromCalendarDate:(NSDate *)fromDate toCalendarDate:(NSDate *)toDate context:(NSManagedObjectContext *)context
{
    logd(@"-------------------------");
    NSDate *worldFromDate = [fromDate earliestWorldDateWithSameCalendarDateAsThisOne];
    NSDate *worldToDate = [toDate latestWorldDateWithSameCalendarDateAsThisOne];
    
    NSArray<PXAlcoholFreeRecord *> *records = [self _fetchFreeRecordsFromDate:worldFromDate toDate:worldToDate context:context];
    
    logd(@"Fetched %lu records in Calendar Dates [%@, %@) ==> Actual [%@, %@)", records.count, fromDate.calendarDateStr, toDate.calendarDateStr, worldFromDate.calendarDateStr, worldToDate.calendarDateStr);
    
    
    NSMutableArray<PXAlcoholFreeRecord *> *recordsInRange = [NSMutableArray array];
    
    NSCalendar *calendar = NSCalendar.currentCalendar;
    NSCalendarUnit units = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay;
    NSDateComponents *fromDateComps = [calendar components:units fromDate:fromDate];
    NSDateComponents *toDateComps = [calendar components:units fromDate:toDate];
    
    for (PXAlcoholFreeRecord *record in records) {
        NSDateComponents *recDateComps = [calendar componentsInTimeZone:[NSTimeZone timeZoneForAlcoholFreeRecord:record] fromDate:record.date];
        
        // Compare [,)
        if ([recDateComps compare:fromDateComps] != NSOrderedAscending &&
            [recDateComps compare:toDateComps] == NSOrderedAscending) {
            [recordsInRange addObject:record];
        } else {
            logd(@"Excluding record with Date/TZ = %@, %.2f (%@)", record.date, [NSTimeZone timeZoneForAlcoholFreeRecord:record].secondsFromGMT/3600., record.timezone);
        }
    }
    
    return recordsInRange;
}

//---------------------------------------------------------------------

+ (void)setFreeDay:(BOOL)freeDay fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate context:(NSManagedObjectContext *)context {
    
    logd(@"-------------------------");
    
    // Looking for any on this Calendar Date (@see README.md)
//    NSDate *worldFromDate = [fromDate earliestWorldDateWithSameCalendarDateAsThisOne];
//    NSDate *worldToDate = [toDate latestWorldDateWithSameCalendarDateAsThisOne];
//
    // Get all possible records and convert their Date to the current Calendar's tz preserving the Calendar Date
    NSArray *freeRecords = [self fetchFreeRecordsFromCalendarDate:fromDate toCalendarDate:toDate context:context];
    NSMutableSet *freeDates = [NSMutableSet set];
    [freeRecords enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        PXAlcoholFreeRecord *record = (PXAlcoholFreeRecord *)obj;
        NSDate *dateInCurrCalendar = [record.date dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:[NSTimeZone timeZoneForAlcoholFreeRecord:record]];
        [freeDates addObject: dateInCurrCalendar];
    }];
    
    NSInteger daysCount = [NSDate daysBetweenDate:fromDate andDate:toDate];
    NSMutableSet *availableDates = [NSMutableSet setWithCapacity:daysCount];
    for (NSInteger day = 0; day < daysCount; day++) {
        NSDate *date = [NSDate changeDate:fromDate byDays:day];
        if (![freeDates containsObject:date]) {
            logd(@"Will create Alcohol Free record for date %@", date.calendarDateStr);
            [availableDates addObject:date];
        } else {
            logd(@"Date %@ is already set to Alcohol Free. Skipping", date.calendarDateStr);
        }
    }
    for (NSDate *date in availableDates) {
        PXAlcoholFreeRecord *alcoholFreeRecord = (PXAlcoholFreeRecord *)[PXAlcoholFreeRecord createInContext:context];
        alcoholFreeRecord.date = date;
        alcoholFreeRecord.timezone = NSCalendar.currentCalendar.timeZone.name; // important to use this to grab our swizzle
        [alcoholFreeRecord saveToServer];
    }
    if (context.hasChanges) [context save:nil];
    
    // why does this method not erase drinking records like the other one below?? Ans: I think b/c it's only used when there is knowledge that the range is empty. Not so good really. See PXMoodDiaryVC ~L307
}

//---------------------------------------------------------------------

+ (void)setFreeDay:(BOOL)freeDay date:(NSDate *)date context:(NSManagedObjectContext *)context {
    logd(@"--------- SetFreeDay: %@, date=%@ ----------", freeDay?@"YES":@"NO", date);
    
    // Looking for any on this Calendar Date (@see README.md)
    NSDate *datePlus1Day = [NSDate nextDayFromDate:date];
    NSMutableArray *alcoholFreeRecords = [self fetchFreeRecordsFromCalendarDate:date toCalendarDate:datePlus1Day context:context].mutableCopy;
    
    logd(@"Found %i AlcoholFree records on that date", (int)alcoholFreeRecords.count);
    
    if (freeDay) {
        // Delete any drink records that fall on that calendar date
        NSArray <PXDrinkRecord *> *drinkRecords = [PXDrinkRecord fetchDrinkRecordsFromCalendarDate:date toCalendarDate:datePlus1Day context:context];
        
        logd(@"Found %i Drink records on that date. Erasing...", (int)drinkRecords.count);
        
        for (PXDrinkRecord *record in drinkRecords) {
            [context deleteObject:record];
        }
        if (alcoholFreeRecords.count == 0) {
            PXAlcoholFreeRecord *alcoholFreeRecord = (PXAlcoholFreeRecord *)[PXAlcoholFreeRecord createInContext:context];
            alcoholFreeRecord.date = date;
            alcoholFreeRecord.timezone = NSCalendar.currentCalendar.timeZone.name; // important to use this to grab our swizzle
            [alcoholFreeRecord saveToServer];
        }
    } else {
        logd(@"Erasing AlcoholFree records on that date");
        for (PXAlcoholFreeRecord *alcoholFreeRecord in alcoholFreeRecords) {
            [alcoholFreeRecord deleteFromServer];
            [context deleteObject:alcoholFreeRecord];
        }
    }
    if (context.hasChanges) [context save:nil];
    
    if (freeDay) [PXStepGuide completeStepWithID:@"drinks"];
}

#pragma mark - Parse

- (void)saveToServer {
    self.parseUpdated = @NO;
    [self.managedObjectContext save:nil];
    
    
    NSMutableDictionary *params = NSMutableDictionary.dictionary;
    if (self.date) params[@"date"] = self.date;
    if (self.timezone) params[@"timezone"] = self.timezone;
    
    // Fail if no network as we need the object ID for later deletions (PXCoreDataManager has some cleanup for failed server saves)
    [DataServer.shared saveDataObjectWithClassName:NSStringFromClass(self.class) objectId:self.parseObjectId isUser:YES params:params ensureSave:NO callback:^(BOOL succeeded, NSString *objectId, NSError *error) {
        if (succeeded) {
            self.parseObjectId = objectId;
            self.parseUpdated = @YES;
            [self.managedObjectContext save:nil];
        }
    }];
}

- (void)deleteFromServer {
    if (self.parseObjectId) {
        [DataServer.shared deleteDataObject:NSStringFromClass(self.class) objectId:self.parseObjectId];
    }
}

@end
