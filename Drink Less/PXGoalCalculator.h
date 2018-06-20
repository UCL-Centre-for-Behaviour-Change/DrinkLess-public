//
//  PXGoalCalculator.h
//  drinkless
//
//  Created by Edward Warrender on 23/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>
#import "PXGoal+Extras.h"

@class NSFetchRequest;

typedef NS_ENUM(NSInteger, PXGoalStatus) {
    PXGoalStatusNone,
    PXGoalStatusExceeded,
    PXGoalStatusHit,
    PXGoalStatusNear,
    PXGoalStatusMissed
};

extern CGFloat const PXExceededPercent;
extern CGFloat const PXMissedPercent;
extern CGFloat const PXExceededScore;
extern CGFloat const PXMissedScore;

extern NSString *const PXQuantityKey;
extern NSString *const PXScoreKey;
extern NSString *const PXStatusKey;
extern NSString *const PXFromDateKey;
extern NSString *const PXToDateKey;
extern NSString *const PXIncompleteKey;

@interface PXGoalCalculator : NSObject

+ (NSArray *)dateRangesForGoal:(PXGoal *)goal;
+ (NSDictionary *)dataWithGoal:(PXGoal *)goal fromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;
+ (NSDictionary *)dataWithGoal:(PXGoal *)goal dateRange:(NSDictionary *)dateRange;
+ (UIImage *)imageForGoalStatus:(PXGoalStatus)goalStatus thumbnail:(BOOL)thumbnail;
+ (UIImage *)imageForGoalStatus:(PXGoalStatus)goalStatus;
+ (UIColor *)colorForGoalStatus:(PXGoalStatus)goalStatus;
+ (NSString *)titleForGoalType:(PXGoalType)goalType quantity:(NSNumber *)quantity;

@end
