//
//  PXMoodDiary.h
//  drinkless
//
//  Created by Edward Warrender on 19/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Parse/Parse.h>

@class PXUserMoodDiaries;

@interface PXMoodDiary : NSObject <NSCoding>

+ (instancetype)moodDiaryWithDate:(NSDate *)date;

@property (strong, nonatomic) NSDate *date;
@property (strong, nonatomic) NSNumber *happiness;
@property (strong, nonatomic) NSNumber *productivity;
@property (strong, nonatomic) NSNumber *clearHeaded;
@property (strong, nonatomic) NSNumber *sleep;
@property (strong, nonatomic) NSString *comment;
@property (strong, nonatomic) NSString *reason;
@property (nonatomic) BOOL goalAchieved;
@property (strong, nonatomic) NSString *parseObjectId;
@property (nonatomic, getter = isParseUpdated) BOOL parseUpdated;

- (void)saveAndLogToParse:(PXUserMoodDiaries *)userMoodDiaries;
- (void)deleteFromParse;

@end
