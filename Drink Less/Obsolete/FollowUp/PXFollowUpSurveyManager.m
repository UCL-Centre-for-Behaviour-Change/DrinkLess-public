//
//  FollowUpManager.m
//  drinkless
//
//  Created by Artsiom Khitryk on 4/11/16.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXFollowUpSurveyManager.h"
#import "PXDailyTaskManager.h"
#import "PXDebug.h"

@interface PXFollowUpSurveyManager()

@end

@implementation PXFollowUpSurveyManager

+ (instancetype)sharedManager {
    static PXFollowUpSurveyManager *sharedManager = nil;
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
    // Note this is NOT the questionnaire that came later involing the 3rd party web page
    NSString *key = [NSString stringWithFormat:@"questionnaireScreen%ldQuestion%ld", (long)screen, (long)section];
    [self.answers setObject:@(answer) forKey:key];
}

- (NSNumber *)getAnswerScreen:(NSInteger)screen section:(NSInteger)section {
    
    NSString *key = [NSString stringWithFormat:@"questionnaireScreen%ldQuestion%ld", (long)screen, (long)section];
    NSNumber *answer = self.answers[key];
    
    return answer;
}

// @TODO Remove this to DailyTaskManager and unwind circular depend.
- (void)surveyCompleted {
    
    [[PXDailyTaskManager sharedManager] completeTaskWithID:@"follow-up"];
    
    [[NSUserDefaults standardUserDefaults] setObject:@(1) forKey:PXFollowUpSurveyDone];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// @TODO I think this should be handled by DailyTaskManager -HK
- (BOOL)hasDone {
#if DBG_DASHBOARD_FORCE_SURVEY
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
