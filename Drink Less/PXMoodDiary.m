//
//  PXMoodDiary.m
//  drinkless
//
//  Created by Edward Warrender on 19/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXMoodDiary.h"
#import "PXUserMoodDiaries.h"
#import "drinkless-Swift.h"

static NSString *const PXDateKey = @"date";
static NSString *const PXTimezoneKey = @"timezone";
static NSString *const PXHappinessKey = @"happiness";
static NSString *const PXProductivityKey = @"productivity";
static NSString *const PXClearHeadedKey = @"clearHeaded";
static NSString *const PXSleepKey = @"sleep";
static NSString *const PXReason = @"reason";
static NSString *const PXComment = @"comment";
static NSString *const PXGoalAchieved = @"PXGoalAchieved";
static NSString *const PXParseUpdatedKey = @"parseUpdated";

@implementation PXMoodDiary

#pragma mark - NSCoding

//+ (instancetype)moodDiaryWithDate:(NSDate *)date {
//    PXMoodDiary *moodDiary = [[PXMoodDiary alloc] init];
//    moodDiary.date = date;
//    moodDiary.timezone = NSCalendar.currentCalendar.timeZone.name;
//    return moodDiary;
//}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.date = [aDecoder decodeObjectForKey:PXDateKey];
        self.timezone = [aDecoder decodeObjectForKey:PXTimezoneKey];
        self.happiness = [aDecoder decodeObjectForKey:PXHappinessKey];
        self.productivity = [aDecoder decodeObjectForKey:PXProductivityKey];
        self.clearHeaded = [aDecoder decodeObjectForKey:PXClearHeadedKey];
        self.sleep = [aDecoder decodeObjectForKey:PXSleepKey];
        self.reason = [aDecoder decodeObjectForKey:PXReason];
        self.comment = [aDecoder decodeObjectForKey:PXComment];
        self.goalAchieved = [aDecoder decodeBoolForKey:PXGoalAchieved];
        self.parseUpdated = [aDecoder decodeBoolForKey:PXParseUpdatedKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.date forKey:PXDateKey];
    [aCoder encodeObject:self.timezone forKey:PXTimezoneKey];
    [aCoder encodeObject:self.happiness forKey:PXHappinessKey];
    [aCoder encodeObject:self.productivity forKey:PXProductivityKey];
    [aCoder encodeObject:self.clearHeaded forKey:PXClearHeadedKey];
    [aCoder encodeObject:self.sleep forKey:PXSleepKey];
    [aCoder encodeObject:self.reason forKey:PXReason];
    [aCoder encodeObject:self.comment forKey:PXComment];
    [aCoder encodeBool:self.goalAchieved forKey:PXGoalAchieved];
    [aCoder encodeBool:self.isParseUpdated forKey:PXParseUpdatedKey];
}

#pragma mark - Parse

- (void)saveAndLogToServer:(PXUserMoodDiaries *)userMoodDiaries {
    self.parseUpdated = NO;
    [userMoodDiaries save];
    
    
    NSMutableDictionary *params = NSMutableDictionary.dictionary;
    if (self.date)      params[@"date"]      = self.date;
    if (self.timezone)  params[@"timezone"] = self.timezone;
    if (self.happiness) params[@"happiness"] = self.happiness;
    if (self.productivity) params[@"productivity"] = self.productivity;
    if (self.clearHeaded) params[@"clearHeaded"] = self.clearHeaded;
    if (self.sleep) params[@"sleep"] = self.sleep;
    if (self.reason) params[@"reason"] = self.reason;
    if (self.comment) params[@"comment"] = self.comment;
    params[@"goalAchieved"] = [NSNumber numberWithBool:self.goalAchieved];
    
    [DataServer.shared saveDataObjectWithClassName:NSStringFromClass(self.class) objectId:self.parseObjectId isUser:YES params:params ensureSave:NO callback:^(BOOL succeeded, NSString *objectId, NSError *error) {
        
        if (succeeded) {
            self.parseObjectId = objectId;
            self.parseUpdated = @YES;
            [userMoodDiaries save];
        }
    }];    
}

- (void)deleteFromParse {
    if (self.parseObjectId) {
        [DataServer.shared deleteDataObject:NSStringFromClass(self.class) objectId:self.parseObjectId];
    }
}

@end
