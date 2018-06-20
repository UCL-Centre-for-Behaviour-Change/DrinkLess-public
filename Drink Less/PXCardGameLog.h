//
//  PXCardGameLog.h
//  drinkless
//
//  Created by Edward Warrender on 11/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

@interface PXCardGameLog : NSObject

- (instancetype)initWithSuccesses:(NSInteger)successes errors:(NSInteger)errors;

@property (strong, nonatomic, readonly) NSDate *date;
@property (strong, nonatomic, readonly) NSNumber *successes;
@property (strong, nonatomic, readonly) NSNumber *errors;
@property (strong, nonatomic, readonly) NSNumber *score;

- (void)saveToParse;

@end
