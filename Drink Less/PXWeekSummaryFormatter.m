//
//  PXWeekSummaryFormatter.m
//  drinkless
//
//  Created by Edward Warrender on 23/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXWeekSummaryFormatter.h"
#import "PXFormatter.h"

@interface PXWeekSummaryFormatter ()

@property (strong, nonatomic) NSNumberFormatter *numberFormatter;

@end

@implementation PXWeekSummaryFormatter

- (instancetype)initWithWeekSummary:(PXWeekSummary *)weekSummary {
    self = [super init];
    if (self) {
        _numberFormatter = [[NSNumberFormatter alloc] init];
        _numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        
        _unitsValue = [self formatUnits:weekSummary.totalUnits];
        _spendingValue  = [self formatSpending:weekSummary.totalSpending];
        _caloriesValue = [self formatCalories:weekSummary.totalCalories];
        
        PXWeekSummary *lastWeek = weekSummary.previousWeekSummary;
        if (lastWeek) {
            CGFloat changeUnits = weekSummary.totalUnits - lastWeek.totalUnits;
            CGFloat changeSpending = weekSummary.totalSpending - lastWeek.totalSpending;
            CGFloat changeCalories = weekSummary.totalCalories - lastWeek.totalCalories;
            
            NSString *valueUnits = [self formatUnits:fabs(changeUnits)];
            NSString *valueSpending = [self formatSpending:fabs(changeSpending)];
            NSString *valueCalories = [self formatCalories:fabs(changeCalories)];
            
            _unitsChange = [self formatString:valueUnits withChange:changeUnits];
            _spendingChange = [self formatString:valueSpending withChange:changeSpending];
            _caloriesChange = [self formatString:valueCalories withChange:changeCalories];
        }
        else {
            _unitsChange = @"-";
            _spendingChange = @"-";
            _caloriesChange = @"-";
        }
    }
    return self;
}

- (NSString *)formatString:(NSString *)string withChange:(CGFloat)change {
    NSString *symbol = change > 0.0 ? @"+" : @"-";
    return [symbol stringByAppendingFormat:@" %@", string];
}

- (NSString *)stringFromNumber:(NSNumber *)number fractional:(BOOL)fractional {
    NSNumberFormatter *formatter = self.numberFormatter;
    formatter.maximumFractionDigits = fractional ? 1 : 0;
    return [formatter stringFromNumber:number];
}

- (NSString *)formatUnits:(CGFloat)value {
    return [self stringFromNumber:@(value) fractional:YES];
}

- (NSString *)formatSpending:(CGFloat)value {
    return [PXFormatter currencyFromNumber:@(value)];
}

- (NSString *)formatCalories:(CGFloat)value {
    return [self stringFromNumber:@(value) fractional:NO];
}

@end
