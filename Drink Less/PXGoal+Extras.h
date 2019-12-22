//
//  PXGoal+Extras.h
//  drinkless
//
//  Created by Edward Warrender on 28/01/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXGoal.h"

typedef NS_ENUM(NSInteger, PXGoalType) {
    PXGoalTypeUnits,
    PXGoalTypeFreeDays,
    PXGoalTypeCalories,
    PXGoalTypeSpending
};

@interface PXGoal (Extras)

- (PXGoal *)copyGoalIntoContext:(NSManagedObjectContext *)context;
- (void)saveToServer;
- (void)deleteFromServer;
+ (NSDictionary *)allGoalTypeTitles;

@property (nonatomic, readonly) NSString *drinkRecordValueKey;
@property (nonatomic, readonly) NSString *goalTypeTitle;
@property (nonatomic, readonly) BOOL isRestorable;
@property (nonatomic, readonly) NSDate *calculatedEndDate;

/** Sorted by start date descending */
+ (NSArray<PXGoal *> *)allGoalsWithContext:(NSManagedObjectContext *)context;


+ (NSArray<PXGoal *> *)lastWeekGoalsWithContext:(NSManagedObjectContext *)context;
+ (NSArray<PXGoal *> *)activeGoalsWithContext:(NSManagedObjectContext *)context;
+ (NSArray<PXGoal *> *)previousGoalsWithContext:(NSManagedObjectContext *)context;



@end
