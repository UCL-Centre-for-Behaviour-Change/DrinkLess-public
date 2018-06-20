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
#import <Parse/Parse.h>
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
    
    BOOL hasStarted = (self.startDate.timeIntervalSinceNow <= 0.0);
    BOOL hasEnded = (self.endDate && self.endDate.timeIntervalSinceNow < 0.0);
    NSDate *date = hasEnded ? self.endDate : self.startDate;
    
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
    return goal;
}

#pragma mark - Parse

- (void)saveToParse {
    self.parseUpdated = @NO;
    [self.managedObjectContext save:nil];
    
    PFObject *object = [PFObject objectWithClassName:NSStringFromClass(self.class)];
    object.objectId = self.parseObjectId;
    object[@"user"] = [PFUser currentUser];
    if (self.goalTypeTitle)   object[@"goalType"]   = self.goalTypeTitle;
    if (self.startDate)       object[@"startDate"]  = self.startDate;
    if (self.endDate)         object[@"endDate"]    = self.endDate;
    if (self.recurring)       object[@"recurring"]  = self.recurring;
    if (self.targetMax)       object[@"targetMax"]  = self.targetMax;
    
    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            self.parseObjectId = object.objectId;
            self.parseUpdated = @YES;
            [self.managedObjectContext save:nil];
        }
    }];
}

- (void)deleteFromParse {
    if (self.parseObjectId) {
        PFObject *object = [PFObject objectWithoutDataWithClassName:NSStringFromClass(self.class)
                                                           objectId:self.parseObjectId];
        [object deleteEventually];
    }
}

#pragma mark - Extras

+ (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
    });
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

@end
