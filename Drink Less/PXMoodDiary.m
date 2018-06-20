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

static NSString *const PXDateKey = @"date";
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

+ (instancetype)moodDiaryWithDate:(NSDate *)date {
    PXMoodDiary *moodDiary = [[PXMoodDiary alloc] init];
    moodDiary.date = date;
    return moodDiary;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.date = [aDecoder decodeObjectForKey:PXDateKey];
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

- (void)saveAndLogToParse:(PXUserMoodDiaries *)userMoodDiaries {
    self.parseUpdated = NO;
    [userMoodDiaries save];
    
    PFObject *object = [PFObject objectWithClassName:NSStringFromClass(self.class)];
    object.objectId = self.parseObjectId;
    object[@"user"] = [PFUser currentUser];
    
    if (self.date)      object[@"date"]      = self.date;
    if (self.happiness) object[@"happiness"] = self.happiness;
    if (self.productivity) object[@"productivity"] = self.productivity;
    if (self.clearHeaded) object[@"clearHeaded"] = self.clearHeaded;
    if (self.sleep) object[@"sleep"] = self.sleep;
    if (self.reason) object[@"reason"] = self.reason;
    if (self.comment) object[@"comment"] = self.comment;
    object[@"goalAchieved"] = [NSNumber numberWithBool:self.goalAchieved];

    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            self.parseObjectId = object.objectId;
            self.parseUpdated = YES;
            [userMoodDiaries save];
        }
    }];
}

- (void)deleteFromParse {
    if (self.parseObjectId) {
        PFObject *object = [PFObject objectWithoutDataWithClassName:NSStringFromClass(self.class)
                                                           objectId:self.parseObjectId];
        [object deleteEventually];
    }
}

@end
