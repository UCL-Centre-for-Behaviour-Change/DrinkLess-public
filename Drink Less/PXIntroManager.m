//
//  PXIntroManager.m
//  drinkless
//
//  Created by Edward Warrender on 21/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXIntroManager.h"
#import "PXDeviceUID.h"
#import "PXGroupsManager.h"
#import <Parse/Parse.h>


static NSString *const PXStageKey = @"stage";
static NSString *const PXAuditAnswersKey = @"auditAnswers";
static NSString *const PXDemographicsAnswers = @"demographicsAnswers";
static NSString *const PXEstimateAnswers = @"estimateAnswers";
static NSString *const PXActualAnswers = @"actualAnswers";
static NSString *const PXAuditScore = @"auditScore";
static NSString *const PXWasHelpful = @"wasHelpful";
static NSString *const PXParseUpdatedKey = @"parseUpdated";

@implementation PXIntroManager

+ (instancetype)sharedManager {
    static PXIntroManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [NSKeyedUnarchiver unarchiveObjectWithFile:[self pathToArchive]];
        if (!sharedManager) {
            sharedManager = [[self alloc] init];
        }
    });
    return sharedManager;
}

- (id)init {
    self = [super init];
    if (self) {
        _stage = PXIntroStagePrivacyPolicy;//PXIntroStageAuditQuestions;//PXIntroStageConsent;
        _auditAnswers = [NSMutableDictionary dictionary];
        _demographicsAnswers = [NSMutableDictionary dictionary];
        _estimateAnswers = [NSMutableDictionary dictionary];
        _actualAnswers = [NSMutableDictionary dictionary];
        _parseUpdated = NO;
    }
    return self;
}

#pragma mark - Persistence

+ (NSString *)pathToArchive {
    NSString *localDocumentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [localDocumentsDirectory stringByAppendingPathComponent:@"intro.data"];
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if (self) {
        _stage = [aDecoder decodeIntegerForKey:PXStageKey];
        _auditAnswers = [aDecoder decodeObjectForKey:PXAuditAnswersKey];
        _demographicsAnswers = [aDecoder decodeObjectForKey:PXDemographicsAnswers];
        _estimateAnswers = [aDecoder decodeObjectForKey:PXEstimateAnswers];
        _actualAnswers = [aDecoder decodeObjectForKey:PXActualAnswers];
        _auditScore = [aDecoder decodeObjectForKey:PXAuditScore];
        _wasHelpful = [aDecoder decodeObjectForKey:PXWasHelpful];
        _parseUpdated = [aDecoder decodeBoolForKey:PXParseUpdatedKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeInteger:self.stage forKey:PXStageKey];
    [aCoder encodeObject:self.auditAnswers forKey:PXAuditAnswersKey];
    [aCoder encodeObject:self.demographicsAnswers forKey:PXDemographicsAnswers];
    [aCoder encodeObject:self.estimateAnswers forKey:PXEstimateAnswers];
    [aCoder encodeObject:self.actualAnswers forKey:PXActualAnswers];
    [aCoder encodeObject:self.auditScore forKey:PXAuditScore];
    [aCoder encodeObject:self.wasHelpful forKey:PXWasHelpful];
    [aCoder encodeBool:self.isParseUpdated forKey:PXParseUpdatedKey];
}

- (void)archive {
    [NSKeyedArchiver archiveRootObject:self toFile:[self.class pathToArchive]];
}

- (void)save {
    self.parseUpdated = NO;
    [self archive];

    PFUser *currentUser = [PFUser currentUser];
    currentUser[PXStageKey] = @(self.stage);
    currentUser[PXAuditAnswersKey] = self.auditAnswers;
    currentUser[PXDemographicsAnswers] = self.demographicsAnswers;
    currentUser[PXEstimateAnswers] = self.estimateAnswers;
    currentUser[PXActualAnswers] = self.actualAnswers;
    NSString *pListPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    NSDictionary *dictionary = [[NSDictionary alloc] initWithContentsOfFile:pListPath];
    NSString *appVersion = [dictionary valueForKey:@"CFBundleShortVersionString"];
    currentUser[@"appVerson"] = appVersion;
    if (self.auditScore) currentUser[PXAuditScore] = self.auditScore;
    if (self.wasHelpful) currentUser[PXWasHelpful] = self.wasHelpful;

    // Assign groupID and UUID
    [currentUser setObject:[PXDeviceUID uid] forKey:@"DeviceId"];
    currentUser[@"groupID"] = [[PXGroupsManager sharedManager] groupID];

    NSLog(@"[PARSE]: Saving Demographic info to user: %@", currentUser);
    [currentUser saveEventually:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"[PARSE]: Success saving Demographic info");
            self.parseUpdated = YES;
            [self archive];
        }
        else {
            NSLog(@"[PARSE]: Error saving Demographic info: %@", error);
        }
    }];
}

#pragma mark - Properties

- (void)setStage:(PXIntroStage)stage {
    _stage = stage;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PXUpdateProgressBar" object:@(stage)];
    if (stage == PXIntroStageFinished) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PXFinishIntro" object:nil];
    }
}

#pragma mark - Read only convenience

- (NSNumber *)gender {
    return self.demographicsAnswers[@"question0"];
    //return self.auditAnswers[@"gender"];
}

- (NSNumber *)birthYear {
    return self.demographicsAnswers[@"question1"];
}

- (NSNumber *)age {
    NSInteger currentYear = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]].year;
    return @(currentYear - self.birthYear.integerValue);
}

- (BOOL)qualifiesForQuestionnaire
{
    NSInteger auditScore = self.auditScore.integerValue;
    NSDate *now = [NSDate date];
    NSInteger currentYear = [[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:now];
    NSInteger age = currentYear - [self.demographicsAnswers[@"question1"] integerValue];
    BOOL isUK = [self.demographicsAnswers[@"question5"] isEqual:@0];
    BOOL isSerious = [self.demographicsAnswers[@"question9"] isEqual:@0];

    return (auditScore >= 8 &&
            age >= 19 &&
            isUK &&
            isSerious);
}

@end
