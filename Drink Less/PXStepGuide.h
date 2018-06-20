//
//  PXStepGuide.h
//  drinkless
//
//  Created by Edward Warrender on 15/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>
#import "PXStep.h"

extern NSString *const PXStepGuideDoneNotification;

@interface PXStepGuide : NSObject

@property (strong, nonatomic) NSArray *steps;

- (NSMutableArray *)checkForNewlyCompletedSteps:(BOOL *)hasFinished;
+ (BOOL)hasDone;
+ (void)markAsDone;
+ (void)completeStepWithID:(NSString *)identifier;
+ (void)debugReset;
+ (NSArray *)loadCompletedSteps;

@end
