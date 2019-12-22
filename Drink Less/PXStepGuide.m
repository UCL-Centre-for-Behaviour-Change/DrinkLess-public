//
//  PXStepGuide.m
//  drinkless
//
//  Created by Edward Warrender on 15/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXStepGuide.h"

NSString *const PXStepGuideDoneNotification = @"PXStepGuideDoneNotification";
static NSString *const PXStepGuideDoneKey = @"stepGuideDone";
static NSString *const PXStepGuideCompletedStepsKey = @"stepGuideCompletedSteps";
static NSString *const PXStepGuideLastCompletedStepsKey = @"stepGuideLastCompletedSteps";

@interface PXStepGuide ()

@property (strong, nonatomic) NSArray *lastCompletedSteps;

@end

@implementation PXStepGuide

@synthesize lastCompletedSteps = _lastCompletedSteps;

- (id)init {
    self = [super init];
    if (self) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"StepGuide" ofType:@"plist"];
        NSArray *plist = [NSArray arrayWithContentsOfFile:path];
        NSMutableArray *steps = [NSMutableArray arrayWithCapacity:plist.count];
        
        for (NSDictionary *dictionary in plist) {
            PXStep *step = [[PXStep alloc] initWithDictionary:dictionary];
            step.completed = [self.lastCompletedSteps containsObject:step.identifier];
            [steps addObject:step];
        }
        _steps = steps.copy;
    }
    return self;
}

- (NSMutableArray *)checkForNewlyCompletedSteps:(BOOL *)hasFinished {
    NSArray *completedSteps = [self.class loadCompletedSteps];
    NSMutableArray *newIndexes = [NSMutableArray array];
    NSInteger numberOfCompleted = 0;
    
    for (NSInteger i = 0; i < self.steps.count; i++) {
        PXStep *step = self.steps[i];
        step.completed = [completedSteps containsObject:step.identifier];
        BOOL wasCompleted = [self.lastCompletedSteps containsObject:step.identifier];
        
        if (step.hasCompleted) {
            numberOfCompleted++;
            if (!wasCompleted) {
                [newIndexes addObject:@(i)];
            }
        }
    }
    if (hasFinished) {
        *hasFinished = numberOfCompleted == self.steps.count;
    }
    self.lastCompletedSteps = completedSteps;
    return newIndexes;
}

- (NSArray *)lastCompletedSteps {
    if (!_lastCompletedSteps) {
        _lastCompletedSteps = [[NSUserDefaults standardUserDefaults] objectForKey:PXStepGuideLastCompletedStepsKey];
    }
    return _lastCompletedSteps;
}

- (void)setLastCompletedSteps:(NSArray *)lastCompletedSteps {
    _lastCompletedSteps = lastCompletedSteps;
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:lastCompletedSteps forKey:PXStepGuideLastCompletedStepsKey];
    [userDefault synchronize];
}

#pragma mark - Class methods

+ (BOOL)hasDone {
    // HKS: Disables Startup step guide as per https://github.com/UCL-Centre-for-Behaviour-Change/DrinkLess/issues/23
    return YES;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL hasDone = [[NSUserDefaults standardUserDefaults] boolForKey:PXStepGuideDoneKey];
    if (!hasDone) {
        // Don't show to old users
        NSDate *firstRunDate = [userDefaults objectForKey:@"firstRun"];
        NSDate *featureDate = [NSDate dateFromComponentDay:16 month:12 year:2015];
        if ([featureDate timeIntervalSinceDate:firstRunDate] > 0.0) {
            return YES;
        }
    }
    return hasDone;
}

+ (void)markAsDone {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setBool:YES forKey:PXStepGuideDoneKey];
    [userDefault synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PXStepGuideDoneNotification object:nil];
}

+ (NSArray *)loadCompletedSteps {
    return [[NSUserDefaults standardUserDefaults] objectForKey:PXStepGuideCompletedStepsKey];
}

+ (void)completeStepWithID:(NSString *)identifier {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSMutableArray *list = [[self loadCompletedSteps] mutableCopy];
    if (!list) {
        list = [NSMutableArray arrayWithObject:identifier];
    } else {
        if ([list containsObject:identifier]) return;
        [list addObject:identifier];
    }
    [userDefault setObject:list forKey:PXStepGuideCompletedStepsKey];
    [userDefault synchronize];
}

+ (void)debugReset {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setBool:NO forKey:PXStepGuideDoneKey];
    [userDefault setObject:nil forKey:PXStepGuideCompletedStepsKey];
    [userDefault setObject:nil forKey:PXStepGuideLastCompletedStepsKey];
    [userDefault synchronize];
}

@end
