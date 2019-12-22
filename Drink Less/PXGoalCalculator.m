//
//  PXGoalCalculator.m
//  drinkless
//
//  Created by Edward Warrender on 23/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXGoalCalculator.h"
#import "PXGoal+Extras.h"
#import "PXCoreDataManager.h"
#import "PXDrinkRecord+Extras.h"
#import "PXFormatter.h"
#import "NSTimeZone+DrinkLess.h"
#import "PXDebug.h"

CGFloat const PXExceededPercent = 120.0;
CGFloat const PXMissedPercent = 85.0;
CGFloat const PXExceededScore = PXExceededPercent / 100.0;
CGFloat const PXMissedScore = PXMissedPercent / 100.0;

NSString *const PXQuantityKey = @"quantity";
NSString *const PXScoreKey = @"score";
NSString *const PXStatusKey = @"status";
NSString *const PXFromDateKey = @"fromDate";
NSString *const PXToDateKey = @"toDate";

@implementation PXGoalCalculator

/** From what I can see this calculates the active weeks of the current goal (for gathering its stats probably). If it's not recurring then it only gets 1 week. Otherwise it keeps getting 1 week date beginning/ends added until the toDate is after NOW */
+ (NSArray *)dateRangesForGoal:(PXGoal *)goal {
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.weekOfYear = 1;
    
    NSTimeZone *goalTZ = [NSTimeZone timeZoneForGoal:goal];
    NSDate *fromDate = [goal.startDate dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:goalTZ]; // Work from this calendar/timezone
	    NSMutableArray *dates = [NSMutableArray array];
    
    BOOL stop = NO;
    while (!stop) {
        NSDate *toDate = [[NSCalendar currentCalendar] dateByAddingComponents:dateComponents toDate:fromDate options:0];
        if (goal.recurring.boolValue) {
            stop = (toDate.timeIntervalSinceNow >= 0.0);
        } else {
            stop = YES;
        }
        [dates addObject:@{PXFromDateKey: fromDate, PXToDateKey: toDate}];
        fromDate = toDate;
    }
    return dates.copy;
}

+ (NSDictionary *)dataWithGoal:(PXGoal *)goal fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {
    NSManagedObjectContext *context = [PXCoreDataManager sharedManager].managedObjectContext;
    CGFloat quantity = 0.0;
    CGFloat score = 0.0;
    
    if (goal.goalType.integerValue == PXGoalTypeFreeDays) {
        // ~~Convert from/to to current calendar equivalents to ensure day calcs are correct~~
        // No need because this already happens in PXGoalCalculator::dateRangesForGoal which is always what supplies this method. (Search project for "dataWithGoal"). So we were converting twice :/
        NSTimeZone *tz = [NSTimeZone timeZoneForGoal:goal];
        NSDate *fromDateInCurrCal = fromDate; //[fromDate dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:tz];
        NSDate *toDateInCurrCal = toDate; //[toDate dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:tz];
        
        NSInteger totalDays = [NSDate daysBetweenDate:fromDateInCurrCal andDate:toDateInCurrCal];
        NSInteger maxAlcoholDays = totalDays - goal.targetMax.floatValue;
        NSUInteger daysDrinking = [PXDrinkRecord fetchCountOfDrinkingDaysFromCalendarDate:fromDate toCalendarDate:toDate context:context];
        score = (daysDrinking == 0) ? PXExceededScore : (CGFloat)maxAlcoholDays / (CGFloat)daysDrinking;
        NSInteger elapsedDays;
        if (toDate.timeIntervalSinceNow > 0.0) {
            elapsedDays = [NSDate daysBetweenDate:fromDateInCurrCal andDate:[NSDate strictDateFromToday]];
        } else {
            elapsedDays = totalDays;
        }
        quantity = (float)elapsedDays - (float)daysDrinking;
        logd(@"GOAL(0): date: %@ - %@ (elapsed=%li) max=%li drank=%li score=%.2f quantity=%.2f", fromDate, toDate, elapsedDays, maxAlcoholDays, daysDrinking, score, quantity);
        
    }
    else {
        NSArray *drinkRecords = [PXDrinkRecord fetchDrinkRecordsFromCalendarDate:fromDate toCalendarDate:toDate context:context];
        NSString *key = goal.drinkRecordValueKey;
        if ([PXDrinkRecord instancesRespondToSelector:NSSelectorFromString(key)]) {
            for (PXDrinkRecord *record in drinkRecords) {
                quantity += [[record valueForKey:key] floatValue];
            }
        }
        score = (quantity == 0) ? PXExceededScore : goal.targetMax.floatValue / quantity;
    }
    
    PXGoalStatus status;
    if (score >= PXExceededScore) {
        status = PXGoalStatusExceeded;
    } else if (score < PXMissedScore) {
        status = PXGoalStatusMissed;
    } else if (score >= PXMissedScore && score < 1.0) {
        status = PXGoalStatusNear;
    } else {
        status = PXGoalStatusHit;
    }
    return @{PXFromDateKey:fromDate, PXToDateKey:toDate, PXQuantityKey: @(quantity), PXScoreKey: @(score), PXStatusKey: @(status)};
}

+ (NSDictionary *)dataWithGoal:(PXGoal *)goal dateRange:(NSDictionary *)dateRange {
    NSDate *fromDate = dateRange[PXFromDateKey];
    NSDate *toDate = dateRange[PXToDateKey];
    return [PXGoalCalculator dataWithGoal:goal fromDate:fromDate toDate:toDate];
}

+ (UIImage *)imageForGoalStatus:(PXGoalStatus)goalStatus thumbnail:(BOOL)thumbnail {
    NSString *imageName = nil;
    switch (goalStatus) {
        case PXGoalStatusExceeded:
            imageName = @"exceed";
            break;
        case PXGoalStatusHit:
            imageName = @"hit";
            break;
        case PXGoalStatusNear:
            imageName = @"near";
            break;
        case PXGoalStatusMissed:
            imageName = @"miss";
            break;
        default:
            imageName = @"pending";
            break;
    }
    imageName = [NSString stringWithFormat:@"goal-%@%@", imageName, thumbnail ? @"-thumbnail": @""];
    return [UIImage imageNamed:imageName];
}

+ (UIImage *)imageForGoalStatus:(PXGoalStatus)goalStatus {
    return [self imageForGoalStatus:goalStatus thumbnail:NO];
}

+ (UIColor *)colorForGoalStatus:(PXGoalStatus)goalStatus {
    switch (goalStatus) {
        case PXGoalStatusExceeded:
            return [UIColor barLightGreen];
        case PXGoalStatusHit:
            return [UIColor drinkLessGreenColor];
        case PXGoalStatusNear:
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enable-textured-colours"]) {
                return [UIColor colorWithPatternImage:[UIImage imageNamed:@"pattern-orange"]];// [UIColor barOrange];
            } else {
                return [UIColor barOrange];
            }
        case PXGoalStatusMissed:
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enable-textured-colours"]) {
                return [UIColor colorWithPatternImage:[UIImage imageNamed:@"pattern-red"]];//[UIColor goalRedColor];
            } else {
                return [UIColor goalRedColor];
            }
        default:
            return nil;
    }
}

+ (NSString *)titleForGoalType:(PXGoalType)goalType quantity:(NSNumber *)quantity {
    BOOL singular = quantity.integerValue == 1;
    switch (goalType) {
        case PXGoalTypeUnits:
            return [NSString stringWithFormat:@"%.f %@", quantity.floatValue, singular ? @"unit" : @"units"];
        case PXGoalTypeCalories:
            return [NSString stringWithFormat:@"%.f %@", quantity.floatValue, singular ? @"calorie" : @"calories"];
        case PXGoalTypeSpending:
            return [PXFormatter currencyFromNumber:quantity];
        case PXGoalTypeFreeDays:
            return [NSString stringWithFormat:@"%.f %@", quantity.floatValue, singular ? @"free day" : @"free days"];
        default:
            return nil;
    }
}

@end
