//
//  PXTimeCalculator.m
//  SmokingDiary
//
//  Created by Edward Warrender on 14/01/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXTimeCalculator.h"

NSString const* PXNumberKey = @"PXNumberKey";
NSString const* PXUnitKey = @"PXUnitKey";
NSString const* PXProgressKey = @"PXProgressKey";
static NSString const* PXTitleKey = @"PXTitleKey";
static NSString const* PXComponentKey = @"PXComponentKey";
static NSString const* PXCapacityKey = @"PXCapacityKey";

@interface PXTimeCalculator ()

@property (strong, nonatomic, readonly) NSArray *components;
@property (nonatomic, readonly) NSCalendarUnit calendarUnits;

@end

@implementation PXTimeCalculator

- (instancetype)initWithMaxComponents:(NSUInteger)maxComponents {
    self = [super init];
    if (self) {
        _components = @[@{PXComponentKey: @(NSCalendarUnitYear),   PXTitleKey: @"year",   PXCapacityKey: @12},
                        @{PXComponentKey: @(NSCalendarUnitMonth),  PXTitleKey: @"month",  PXCapacityKey: @31},
                        @{PXComponentKey: @(NSCalendarUnitDay),    PXTitleKey: @"day",    PXCapacityKey: @24},
                        @{PXComponentKey: @(NSCalendarUnitHour),   PXTitleKey: @"hour",   PXCapacityKey: @60},
                        @{PXComponentKey: @(NSCalendarUnitMinute), PXTitleKey: @"minute", PXCapacityKey: @60},
                        @{PXComponentKey: @(NSCalendarUnitSecond), PXTitleKey: @"second"}];
        
        _calendarUnits = 0;
        for (NSDictionary *dictionary in _components) {
            NSCalendarUnit component = [dictionary[PXComponentKey] unsignedIntegerValue];
            _calendarUnits = _calendarUnits | component;
        }
        if (maxComponents == 0) {
            maxComponents = _components.count;
        }
        _maxComponents = maxComponents;
    }
    return self;
}

#pragma mark - Internal

- (NSString *)concatenateTimes:(NSArray *)times {
    NSInteger timesCount = times.count;
    if (timesCount == 0) {
        return @"unknown";
    } else if (timesCount == 1) {
        return times.firstObject;
    }
    NSMutableString *concatenated = nil;
    for (NSInteger index = 0; index < timesCount; index++) {
        NSString *text = times[index];
        if (index == 0) {
            concatenated = text.mutableCopy;
        } else if (index == timesCount - 1) {
            [concatenated appendFormat:@" and %@", text];
        } else {
            [concatenated appendFormat:@", %@", text];
        }
    }
    return concatenated.copy;
}

#pragma mark - External

- (NSDateComponents *)dateComponentsBetweenDate:(NSDate *)dateA andDate:(NSDate *)dateB hasPassed:(BOOL *)passed {
    BOOL isDateAEarlier = [dateA timeIntervalSinceDate:dateB] < 0.0;
    if (passed) {
        *passed = !isDateAEarlier;
    }
    NSDate *fromDate = isDateAEarlier ? dateA : dateB;
    NSDate *toDate = isDateAEarlier ? dateB : dateA;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [calendar components:self.calendarUnits fromDate:fromDate toDate:toDate options:0];
}

- (NSArray *)statisticsBetweenDate:(NSDate *)dateA andDate:(NSDate *)dateB hasPassed:(BOOL *)passed {
    NSDateComponents *dateComponents = [self dateComponentsBetweenDate:dateA andDate:dateB hasPassed:passed];
    
    NSMutableArray *statistics = [NSMutableArray array];
    NSInteger previousValue = 0;
    for (NSInteger index = self.components.count - 1; index >= 0; index--) {
        NSDictionary *dictionary = self.components[index];
        NSString *title = dictionary[PXTitleKey];
        NSInteger value = [[dateComponents valueForKey:title] integerValue];
        NSString *plural = (value == 1) ? @"" : @"s";
        NSString *units = [NSString stringWithFormat:@"%@%@", title.capitalizedString, plural];
        NSNumber *capacity = dictionary[PXCapacityKey];
        CGFloat progress = 1.0;
        if (capacity) {
            progress = previousValue / (CGFloat)capacity.integerValue;
        }
        NSDictionary *statistic = @{PXNumberKey: @(value), PXUnitKey: units, PXProgressKey: @(progress)};
        [statistics insertObject:statistic atIndex:0];
        
        previousValue = value;
    }
    return statistics.copy;
}

- (NSArray *)statisticsBetweenNowAndDate:(NSDate *)date hasPassed:(BOOL *)passed {
    return [self statisticsBetweenDate:[NSDate date] andDate:date hasPassed:passed];
}

- (NSString *)timeBetweenDate:(NSDate *)dateA andDate:(NSDate *)dateB {
    NSDateComponents *dateComponents = [self dateComponentsBetweenDate:dateA andDate:dateB hasPassed:nil];
    
    NSMutableArray *times = [NSMutableArray array];
    for (NSInteger index = 0; index < self.components.count; index++) {
        NSDictionary *dictionary = self.components[index];
        NSString *title = dictionary[PXTitleKey];
        NSInteger value = [[dateComponents valueForKey:title] integerValue];
        if (value > 0) {
            NSString *plural = (value == 1) ? @"" : @"s";
            NSString *time = [NSString stringWithFormat:@"%li %@%@", (long)value, title, plural];
            [times addObject:time];
            
            if (times.count >= self.maxComponents) {
                break;
            }
        } else {
            if (times.count != 0) {
                break;
            }
        }
    }
    return [self concatenateTimes:times];
}

- (NSString *)timeBetweenNowAndDate:(NSDate *)date {
    return [self timeBetweenDate:[NSDate date] andDate:date];
}

@end
