//
//  PXWeekSummary.h
//  drinkless
//
//  Created by Edward Warrender on 14/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

@interface PXWeekSummary : NSObject

@property (strong, nonatomic, readonly) NSDate *startDate;
@property (strong, nonatomic, readonly) NSDate *endDate;
@property (strong, nonatomic, readonly) NSDate *lastDate;
@property (strong, nonatomic, readonly) NSArray *drinkRecords;
@property (nonatomic, readonly) NSInteger alcoholFreeDays;
@property (nonatomic, readonly) CGFloat totalUnits;
@property (nonatomic, readonly) CGFloat totalCalories;
@property (nonatomic, readonly) CGFloat totalSpending;
@property (weak, nonatomic) PXWeekSummary *previousWeekSummary;

- (instancetype)initWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate drinkRecords:(NSArray *)drinkRecords alcoholFreeDays:(NSInteger)alcoholFreeDays;

@end
