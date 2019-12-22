//
//  FollowUpManager.h
//  drinkless
//
//  Created by Artsiom Khitryk on 4/11/16.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

static NSString *const PXFollowUpSurveyDoneNotification = @"PXFollowUpSurveyDoneNotification";
static NSString *const PXFollowUpSurveyDone = @"PXFollowUpSurveyDone";

@interface PXFollowUpSurveyManager : NSObject

@property (nonatomic, strong) NSMutableDictionary *answers;

+ (instancetype)sharedManager;

- (void)setAnswer:(NSInteger)answer screen:(NSInteger)screen section:(NSInteger)section;
- (NSNumber *)getAnswerScreen:(NSInteger)screen section:(NSInteger)section;

- (void)surveyCompleted;
- (BOOL)hasDone;

@end
