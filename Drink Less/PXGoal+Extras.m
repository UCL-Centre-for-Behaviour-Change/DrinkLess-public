//
//  PXGoal+Extras.m
//  drinkless
//
//  Created by Edward Warrender on 28/01/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXGoal+Extras.h"
#import "NSManagedObject+PXFindByID.h"
#import "drinkless-Swift.h"
#import "PXFormatter.h"


@implementation PXGoal (Extras)

- (NSString *)title {
    [self willAccessValueForKey:@"title"];
    
    PXGoalType goalType = self.goalType.integerValue;
    BOOL singular = (self.targetMax.integerValue == 1);
    
    NSString *title;
    switch (goalType) {
        case PXGoalTypeUnits: {
            NSString *type = singular ? @"unit" : @"units";
            title = [NSString stringWithFormat:@"Drink less than %@ %@ a week", self.targetMax, type];
        } break;
        case PXGoalTypeCalories: {
            NSString *type = singular ? @"calorie" : @"calories";
            title = [NSString stringWithFormat:@"Drink less than %@ %@ a week", self.targetMax, type];
        } break;
        case PXGoalTypeSpending: {
            NSString *price = [PXFormatter currencyFromNumber:self.targetMax];
            title = [NSString stringWithFormat:@"Spend less than %@ a week", price];
        } break;
        case PXGoalTypeFreeDays: {
            NSString *type = singular ? @"free day" : @"free days";
            title = [NSString stringWithFormat:@"Have at least %@ alcohol %@ a week", self.targetMax, type];
        } break;
        default:
            title = @"";
            break;
    }
    [self didAccessValueForKey:@"title"];
    return title;
}

- (NSString *)overview {
    [self willAccessValueForKey:@"overview"];
    NSTimeZone *goalTZ = [NSTimeZone timeZoneForGoal:self];
    NSDate *startDateInCurrCal = [self.startDate dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:goalTZ];
    NSDate *endDateInCurrCal = [self.endDate dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:goalTZ];
    
    BOOL hasStarted = (startDateInCurrCal.timeIntervalSinceNow <= 0.0);
    BOOL hasEnded = (self.endDate && endDateInCurrCal.timeIntervalSinceNow < 0.0);
    NSDate *date = hasEnded ? endDateInCurrCal : startDateInCurrCal;
    
    NSString *prefix = nil;
    if (!hasStarted) {
        prefix = @"Start";
    } else if (hasEnded) {
        prefix = @"Ended";
    } else {
        prefix = @"Started";
    }
    NSString *overview = [NSString stringWithFormat:@"%@ on %@", prefix, [[self.class dateFormatter] stringFromDate:date]];
    
    [self didAccessValueForKey:@"overview"];
    return overview;
}

- (PXGoal *)copyGoalIntoContext:(NSManagedObjectContext *)context {
    PXGoal *goal = (PXGoal *)[PXGoal createInContext:context];
    goal.startDate = self.startDate;
    goal.endDate = self.endDate;
    goal.goalType = self.goalType;
    goal.recurring = self.recurring;
    goal.targetMax = self.targetMax;
    goal.parseObjectId = self.parseObjectId;
    goal.parseUpdated = self.parseUpdated;
    goal.timezone = self.timezone;
    return goal;
}

#pragma mark - Parse

- (void)saveToServer {
    self.parseUpdated = @NO;
    [self.managedObjectContext save:nil];
    
    NSMutableDictionary *params = NSMutableDictionary.dictionary;
    if (self.goalTypeTitle)   params[@"goalType"]   = self.goalTypeTitle;
    if (self.startDate)       params[@"startDate"]  = self.startDate;
    if (self.endDate)         params[@"endDate"]    = self.endDate;
    if (self.recurring)       params[@"recurring"]  = self.recurring;
    if (self.targetMax)       params[@"targetMax"]  = self.targetMax;
    if (self.timezone)        params[@"timezone"]   = self.timezone;

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

#pragma mark - Extras

+ (NSDateFormatter *)dateFormatter {
    NSDateFormatter *dateFormatter = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
//    });
    return dateFormatter;
}

+ (NSDictionary *)allGoalTypeTitles {
    static NSDictionary *dictionary = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dictionary = @{@(PXGoalTypeUnits): @"Units",
                       @(PXGoalTypeCalories): @"Calories",
                       @(PXGoalTypeSpending): @"Spending",
                       @(PXGoalTypeFreeDays): @"Alcohol free days"};
    });
    return dictionary;
}

- (NSString *)goalTypeTitle {
    return [self.class allGoalTypeTitles][self.goalType];
}

- (NSString *)drinkRecordValueKey {
    switch (self.goalType.integerValue) {
        case PXGoalTypeUnits:
            return @"totalUnits";
        case PXGoalTypeCalories:
            return @"totalCalories";
        case PXGoalTypeSpending:
            return @"totalSpending";
        default:
            NSLog(@"Goal type was unrecognised");
            return nil;
    }
}

- (BOOL)isRestorable {
    BOOL restorable = NO;
    if (self.recurring.boolValue) {
        restorable = YES;
    } else {
        if (self.calculatedEndDate.timeIntervalSinceNow > 0.0) {
            restorable = YES;
        }
    }
    return restorable;
}

- (NSDate *)calculatedEndDate {
    if (!self.recurring.boolValue) {
        NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
        dateComponents.weekOfYear = 1;
        return [[NSCalendar currentCalendar] dateByAddingComponents:dateComponents toDate:self.startDate options:0];
    }
    return nil;
}

+ (NSArray<PXGoal *> *)allGoalsWithContext:(NSManagedObjectContext *)context {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PXGoal"];
    fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:NO]];
    
    NSArray<PXGoal *> *goals = [context executeFetchRequest:fetchRequest error:nil];
    
    return goals;
}

//---------------------------------------------------------------------

+ (NSArray<PXGoal *> *)lastWeekGoalsWithContext:(NSManagedObjectContext *)context {
    NSArray<PXGoal *> *goals = [self allGoalsWithContext:context];
    // @TODO: For efficioency we could grab just the possibly goals using the earliest/latest possible world date's for the endDate comparison. But I think goal numbers are very low and this wont be an overtaxing op
    
    NSDate *thisWeek = [NSDate startOfThisWeek];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.weekOfYear = -1;
    NSDate *lastWeek = [calendar dateByAddingComponents:dateComponents toDate:thisWeek options:0];
    
    NSMutableArray<PXGoal *> *lastWeekGoals = NSMutableArray.array;
    for (PXGoal *goal in goals) {
        NSTimeZone *goalTZ = [NSTimeZone timeZoneForGoal:goal]; // handles failsafe
        NSDate *startDateInCurrCal = [goal.startDate dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:goalTZ];
        NSDate *endDateInCurrCal = [goal.endDate dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:goalTZ];
        
        // Last Week (from former template in coredata) :=
        // enddate == empty && startDate < lastWeek
        // OR
        // endate > LastWeek && endDate <= thisWeek
        
        NSComparisonResult startDateLastWeekComparison = [calendar compareDate:startDateInCurrCal toDate:lastWeek toUnitGranularity:NSCalendarUnitDay];
        
        if (goal.endDate == nil) {
            if (startDateLastWeekComparison == NSOrderedAscending) {
                [lastWeekGoals addObject:goal];
            }
            continue;
        }
        
        NSComparisonResult endDateLastWeekComparison = [calendar compareDate:endDateInCurrCal toDate:lastWeek toUnitGranularity:NSCalendarUnitDay];
        NSComparisonResult endDateThisWeekComparison = [calendar compareDate:endDateInCurrCal toDate:thisWeek toUnitGranularity:NSCalendarUnitDay];
        
        if (endDateLastWeekComparison == NSOrderedDescending && (endDateThisWeekComparison == NSOrderedAscending || endDateThisWeekComparison == NSOrderedSame)) {
            [lastWeekGoals addObject:goal];
        }
    }
            
    return lastWeekGoals;
}

//---------------------------------------------------------------------

+ (NSArray<PXGoal *> *)activeGoalsWithContext:(NSManagedObjectContext *)context {
    
    NSArray<PXGoal *> *goals = [self allGoalsWithContext:context];
    NSDate *today = [NSDate strictDateFromToday];
    NSCalendar *calendar = [NSCalendar currentCalendar];

    NSMutableArray<PXGoal *> *activeGoals = NSMutableArray.array;
    for (PXGoal *goal in goals) {
        NSTimeZone *goalTZ = [NSTimeZone timeZoneForGoal:goal]; // handles failsafe
        NSDate *endDateInCurrCal = [goal.endDate dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:goalTZ];
        
        // Last Week (from former template in coredata) :=
        // enddate == empty && startDate < lastWeek
        // OR
        // endate > LastWeek && endDate <= thisWeek
        
        NSComparisonResult endDateTodayComparison = [calendar compareDate:endDateInCurrCal toDate:today toUnitGranularity:NSCalendarUnitDay];
        
        if (goal.endDate == nil || endDateTodayComparison == NSOrderedDescending) {
            [activeGoals addObject:goal];
        }
    }
    
    return activeGoals;
}

//---------------------------------------------------------------------

+ (NSArray<PXGoal *> *)previousGoalsWithContext:(NSManagedObjectContext *)context {
    
    NSArray<PXGoal *> *goals = [self allGoalsWithContext:context];
    NSDate *today = [NSDate strictDateFromToday];
    NSCalendar *calendar = [NSCalendar currentCalendar];

    NSMutableArray<PXGoal *> *inactiveGoals = NSMutableArray.array;
    for (PXGoal *goal in goals) {
        NSTimeZone *goalTZ = [NSTimeZone timeZoneForGoal:goal]; // handles failsafe
        NSDate *endDateInCurrCal = [goal.endDate dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:goalTZ];
        
        // Last Week (from former template in coredata) :=
        // enddate == empty && startDate < lastWeek
        // OR
        // endate > LastWeek && endDate <= thisWeek
        
        NSComparisonResult endDateTodayComparison = [calendar compareDate:endDateInCurrCal toDate:today toUnitGranularity:NSCalendarUnitDay];
        
        if (goal.endDate != nil && (endDateTodayComparison == NSOrderedAscending || endDateTodayComparison == NSOrderedSame)) {
            [inactiveGoals addObject:goal];
        }
    }
    
    return inactiveGoals;
}
@end
