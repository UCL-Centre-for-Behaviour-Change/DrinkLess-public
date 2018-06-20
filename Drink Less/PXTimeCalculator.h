//
//  PXTimeCalculator.h
//  SmokingDiary
//
//  Created by Edward Warrender on 14/01/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

extern NSString const* PXNumberKey;
extern NSString const* PXUnitKey;
extern NSString const* PXProgressKey;

@interface PXTimeCalculator : NSObject

- (instancetype)initWithMaxComponents:(NSUInteger)maxComponents;

@property (nonatomic) NSUInteger maxComponents;

- (NSArray *)statisticsBetweenDate:(NSDate *)dateA andDate:(NSDate *)dateB hasPassed:(BOOL *)passed;
- (NSArray *)statisticsBetweenNowAndDate:(NSDate *)date hasPassed:(BOOL *)passed;
- (NSString *)timeBetweenDate:(NSDate *)dateA andDate:(NSDate *)dateB;
- (NSString *)timeBetweenNowAndDate:(NSDate *)date;

@end
