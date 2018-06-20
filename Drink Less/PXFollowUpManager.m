//
//  FollowUpManager.m
//  drinkless
//
//  Created by Artsiom Khitryk on 4/11/16.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXFollowUpManager.h"
#import "PXDailyTaskManager.h"
#import "PXDebug.h"

@interface PXFollowUpManager()

@end

@implementation PXFollowUpManager

+ (instancetype)sharedManager {
    static PXFollowUpManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sharedManager) {
            sharedManager = [[self alloc] init];
        }
    });
    return sharedManager;
}

- (id)init {
    self = [super init];
    if (self) {

        self.answers = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Public methods

- (void)setAnswer:(NSInteger)answer screen:(NSInteger)screen section:(NSInteger)section {
    
    NSString *key = [NSString stringWithFormat:@"questionnaireScreen%ldQuestion%ld", (long)screen, (long)section];
    [self.answers setObject:@(answer) forKey:key];
}

- (NSNumber *)getAnswerScreen:(NSInteger)screen section:(NSInteger)section {
    
    NSString *key = [NSString stringWithFormat:@"questionnaireScreen%ldQuestion%ld", (long)screen, (long)section];
    NSNumber *answer = self.answers[key];
    
    return answer;
}

- (void)surveyCompleted {
    
    [[PXDailyTaskManager sharedManager] completeTaskWithID:@"follow-up"];
    
    [[NSUserDefaults standardUserDefaults] setObject:@(1) forKey:PXFollowUpSurveyDone];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)hasDone {
#if FORCE_SURVEY
    return NO;
#endif
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL hasDone = [[NSUserDefaults standardUserDefaults] boolForKey:PXFollowUpSurveyDone];
    if (!hasDone) {
        
        NSDate *firstRunDate = [userDefaults objectForKey:@"firstRun"];
        NSInteger days = [NSDate daysBetweenDate:firstRunDate andDate:[NSDate date]];
        if (days >= 31)
            hasDone = NO;
        else
            hasDone = YES;
    }
    
    return hasDone;
}

@end
