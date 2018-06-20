//
//  PXWeekSummaryFormatter.h
//  drinkless
//
//  Created by Edward Warrender on 23/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>
#import "PXWeekSummary.h"

@interface PXWeekSummaryFormatter : NSObject

- (instancetype)initWithWeekSummary:(PXWeekSummary *)weekSummary;

@property (strong, nonatomic, readonly) NSString *unitsValue;
@property (strong, nonatomic, readonly) NSString *spendingValue;
@property (strong, nonatomic, readonly) NSString *caloriesValue;
@property (strong, nonatomic, readonly) NSString *unitsChange;
@property (strong, nonatomic, readonly) NSString *spendingChange;
@property (strong, nonatomic, readonly) NSString *caloriesChange;

- (NSString *)formatUnits:(CGFloat)value;
- (NSString *)formatSpending:(CGFloat)value;
- (NSString *)formatCalories:(CGFloat)value;

@end
