//
//  PXGoalStatistics.m
//  drinkless
//
//  Created by Edward Warrender on 23/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXGoalStatistics.h"
#import "PXFormatter.h"

@interface PXGoalStatistics ()

@property (nonatomic) PXStatisticRegion region;

@end

@implementation PXGoalStatistics

- (instancetype)initWithGoal:(PXGoal *)goal region:(PXStatisticRegion)region {
    self = [super init];
    if (self) {
        _goal = goal;
        _region = region;
        [self calculateData];
    }
    return self;
}

- (void)calculateData {
    NSArray *dateRanges = [PXGoalCalculator dateRangesForGoal:self.goal];
    if (self.region == PXStatisticRegionCurrentIncomplete) {
        _data = [PXGoalCalculator dataWithGoal:self.goal dateRange:dateRanges.lastObject];
    }
    else if (self.region == PXStatisticRegionLastCompleted) {
        for (NSDictionary *dateRange in dateRanges) {
            NSDate *toDate = dateRange[PXToDateKey];
            if (toDate.timeIntervalSinceNow <= 0.0) {
                _data = [PXGoalCalculator dataWithGoal:self.goal dateRange:dateRange];
            } else {
                // The rest of the periods are in the future
                break;
            }
        }
    }
    else if (self.region == PXStatisticRegionAllCompleted) {
        NSInteger streak = 0;
        _exceedCount = 0;
        _hitCount = 0;
        _nearCount = 0;
        _missCount = 0;
        _successStreak = 0;
        _allData = [NSMutableArray array];
        
        for (NSDictionary *dateRange in dateRanges) {
            NSDate *toDate = dateRange[PXToDateKey];
            if (toDate.timeIntervalSinceNow <= 0.0) {
                _data = [PXGoalCalculator dataWithGoal:self.goal dateRange:dateRange];
                [_allData addObject:_data];
                
                PXGoalStatus status = [_data[PXStatusKey] integerValue];
                BOOL successful = (status == PXGoalStatusExceeded || status == PXGoalStatusHit);
                if (successful) {
                    streak++;
                    if (streak > _successStreak) {
                        _successStreak = streak;
                    }
                } else {
                    streak = 0;
                }
                switch (status) {
                    case PXGoalStatusExceeded:
                        _exceedCount++;
                        break;
                    case PXGoalStatusHit:
                        _hitCount++;
                        break;
                    case PXGoalStatusNear:
                        _nearCount++;
                        break;
                    case PXGoalStatusMissed:
                        _missCount++;
                        break;
                    default:
                        break;
                }
            } else {
                // The rest of the periods are in the future
                if (_allData.count == 0) {
                    _completionDate = toDate;
                }
                break;
            }
        }
        _successPercentage = ((_exceedCount + _hitCount) / (float)_allData.count) * 100;
    }
}

//---------------------------------------------------------------------

- (UIImage *)icon {
    PXGoalStatus status = [self.data[PXStatusKey] integerValue];
    UIImage *icon = [PXGoalCalculator imageForGoalStatus:status thumbnail:YES];
    return icon;
}

//---------------------------------------------------------------------

- (NSString *)shortTitle {
    NSNumber *quantity = self.goal.targetMax;
    BOOL singular = quantity.integerValue == 1.0f;
    switch (self.goal.goalType.integerValue) {
        case PXGoalTypeUnits:
            return [NSString stringWithFormat:@"Drink less than %.f %@", quantity.floatValue, singular ? @"unit" : @"units"];
        case PXGoalTypeCalories:
            return [NSString stringWithFormat:@"Consume less than %.f %@", quantity.floatValue, singular ? @"calorie" : @"calories"];
        case PXGoalTypeSpending:
            return [NSString stringWithFormat:@"Spend less than %@", [PXFormatter currencyFromNumber:quantity]];
        case PXGoalTypeFreeDays:
            return [NSString stringWithFormat:@"%.f or more alcohol %@", quantity.floatValue, singular ? @"free days" : @"free days"];
        default:
            return nil;
    }
}

@end
