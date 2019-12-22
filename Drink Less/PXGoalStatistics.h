//
//  PXGoalStatistics.h
//  drinkless
//
//  Created by Edward Warrender on 23/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>
#import "PXGoalCalculator.h"

@class PXGoal;

typedef NS_ENUM(NSInteger, PXStatisticRegion) {
    PXStatisticRegionCurrentIncomplete,
    PXStatisticRegionLastCompleted,
    PXStatisticRegionAllCompleted
};

@interface PXGoalStatistics : NSObject

- (instancetype)initWithGoal:(PXGoal *)goal region:(PXStatisticRegion)region;

@property (strong, nonatomic, readonly) PXGoal *goal;
@property (strong, nonatomic, readonly) NSDictionary *data;
@property (strong, nonatomic, readonly) NSMutableArray *allData;
@property (strong, nonatomic, readonly) NSDate *completionDate;
@property (nonatomic, readonly) NSInteger exceedCount;
@property (nonatomic, readonly) NSInteger hitCount;
@property (nonatomic, readonly) NSInteger nearCount;
@property (nonatomic, readonly) NSInteger missCount;
@property (nonatomic, readonly) NSInteger successStreak;
@property (nonatomic, readonly) CGFloat successPercentage;

@property (nonatomic, readonly) UIImage *icon;
@property (nonatomic, readonly) NSString *shortTitle;

@end
