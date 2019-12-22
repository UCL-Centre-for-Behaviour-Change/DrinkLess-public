//
//  PXCardGameLog.m
//  drinkless
//
//  Created by Edward Warrender on 11/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXCardGameLog.h"
#import "drinkless-Swift.h"

static NSString *const PXDateKey = @"date";
static NSString *const PXSuccessesKey = @"successes";
static NSString *const PXErrorsKey = @"errors";
static NSString *const PXGameScoreKey = @"score";

static NSInteger const PXSuccessValue = 1;
static NSInteger const PXErrorValue = -2;

@implementation PXCardGameLog

@synthesize score = _score;

- (instancetype)initWithSuccesses:(NSInteger)successes errors:(NSInteger)errors {
    self = [super init];
    if (self) {
        _date = [NSDate date];
        _successes = @(successes);
        _errors = @(errors);
    }
    return self;
}

#pragma mark - Score is calculated not saved so values can be changed with future updates

- (NSNumber *)score {
    if (!_score) {
        NSInteger score = self.successes.integerValue * PXSuccessValue;
        NSInteger penalty = self.errors.integerValue * PXErrorValue;
        _score = @(score + penalty);
    }
    return _score;
}

#pragma mark - Parse

- (void)saveToServer {
    NSMutableDictionary *params = NSMutableDictionary.dictionary;
    params[PXDateKey] = self.date;
    params[PXSuccessesKey] = self.successes;
    params[PXErrorsKey] = self.errors;
    params[PXGameScoreKey] = self.score;
    
    [DataServer.shared saveDataObjectWithClassName:NSStringFromClass(self.class) objectId:nil isUser:YES params:params ensureSave:YES callback:nil];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _date = [aDecoder decodeObjectForKey:PXDateKey];
        _successes = [aDecoder decodeObjectForKey:PXSuccessesKey];
        _errors = [aDecoder decodeObjectForKey:PXErrorsKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.date forKey:PXDateKey];
    [aCoder encodeObject:self.successes forKey:PXSuccessesKey];
    [aCoder encodeObject:self.errors forKey:PXErrorsKey];
}

@end
