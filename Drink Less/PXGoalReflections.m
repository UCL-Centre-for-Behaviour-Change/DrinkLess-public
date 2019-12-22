//
//  PXGoalReflections.m
//  drinkless
//
//  Created by Edward Warrender on 05/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXGoalReflections.h"
#import "drinkless-Swift.h"

static NSString *const PXWhatHasWorkedKey = @"whatHasWorked";
static NSString *const PXWhatHasNotWorkedKey = @"whatHasNotWorked";

@interface PXGoalReflections ()

@property (strong, nonatomic) NSUserDefaults *userDefaults;

@end

@implementation PXGoalReflections

- (id)init {
    self = [super init];
    if (self) {
        self.userDefaults = [NSUserDefaults standardUserDefaults];
    }
    return self;
}

+ (instancetype)loadGoalReflections {
    PXGoalReflections *goalReflections = [[PXGoalReflections alloc] init];
    [goalReflections reload];
    return goalReflections;
}

- (void)reload {
    NSArray *whatHasWorked = [self.userDefaults objectForKey:PXWhatHasWorkedKey];
    if (!whatHasWorked) whatHasWorked = @[@""];
    self.whatHasWorked = whatHasWorked.mutableCopy;
    
    NSArray *whatHasNotWorked = [self.userDefaults objectForKey:PXWhatHasNotWorkedKey];
    if (!whatHasNotWorked) whatHasNotWorked = @[@""];
    self.whatHasNotWorked = whatHasNotWorked.mutableCopy;
}

- (void)save {
    // Strip out empty bullet points unless it only contains one - the placeholder
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"length != 0"];
    if (self.whatHasWorked.count > 1) {
        [self.whatHasWorked filterUsingPredicate:predicate];
    }
    if (self.whatHasNotWorked.count > 1) {
        [self.whatHasNotWorked filterUsingPredicate:predicate];
    }
    
    [self.userDefaults setObject:self.whatHasWorked forKey:PXWhatHasWorkedKey];
    [self.userDefaults setObject:self.whatHasNotWorked forKey:PXWhatHasNotWorkedKey];
    [self.userDefaults synchronize];
    
    NSMutableDictionary *params = NSMutableDictionary.dictionary;
    params[@"whatHasWorked"] = self.whatHasWorked;
    params[@"whatHasNotWorked"] = self.whatHasNotWorked;
    [DataServer.shared saveDataObjectWithClassName:NSStringFromClass(self.class) objectId:nil isUser:YES params:params ensureSave:YES callback:nil];
}

@end
