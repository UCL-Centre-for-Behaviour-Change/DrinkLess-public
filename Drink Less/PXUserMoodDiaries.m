//
//  PXUserMoodDiaries.m
//  drinkless
//
//  Created by Edward Warrender on 19/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXUserMoodDiaries.h"
#import "PXMoodDiary.h"
#import "NSTimeZone+DrinkLess.h"

static NSString *const PXMoodDiariesKey = @"moodDiaries";

@implementation PXUserMoodDiaries

+ (instancetype)loadMoodDiaries {
    PXUserMoodDiaries *userMoodDiaries = [NSKeyedUnarchiver unarchiveObjectWithFile:[self archiveFilePath]];
    if (!userMoodDiaries) {
        userMoodDiaries = [[PXUserMoodDiaries alloc] init];
    }
    return userMoodDiaries;
}

+ (void)deleteAllData
{
    NSError *e;
    [[NSFileManager defaultManager] removeItemAtPath:[self archiveFilePath] error:&e];
    if (e) {
        NSLog(@"******* ERROR: %@ *******", e);
    }
}

- (id)init {
    self = [super init];
    if (self) {
        self.moodDiaries = @[].mutableCopy;
    }
    return self;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.moodDiaries = [[aDecoder decodeObjectForKey:PXMoodDiariesKey] mutableCopy];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.moodDiaries forKey:PXMoodDiariesKey];
}

+ (NSString *)archiveFilePath {
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [directoryPaths.lastObject stringByAppendingPathComponent:@"userMoodDiaries.dat"];
}

- (void)save {
    [NSKeyedArchiver archiveRootObject:self toFile:[[self class] archiveFilePath]];
}

#pragma mark - Properties

- (PXMoodDiary *)fetchTodaysMoodDiary {
    NSDate *today = [NSDate strictDateFromToday];
    PXMoodDiary *todaysMoodDiary;
    for (PXMoodDiary *moodDiary in self.moodDiaries.reverseObjectEnumerator) { // reversed search for efficiency
        NSTimeZone *tz = [NSTimeZone timeZoneForMoodDiary:moodDiary];
        NSDate *moodDiaryDateInCurrCal = [moodDiary.date dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:tz];
        if ([NSCalendar.currentCalendar compareDate:moodDiaryDateInCurrCal toDate:today toUnitGranularity:NSCalendarUnitDay] == NSOrderedSame) {
            todaysMoodDiary = moodDiary;
            break;
        }
    }
    return todaysMoodDiary;
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date == %@", today];
//    return [self.moodDiaries filteredArrayUsingPredicate:predicate].firstObject;
}

#pragma mark - Convenience

- (void)calculateStreaks {
    _currentStreak = 0;
    _highestStreak = 0;
    NSDate *previousDate;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    // HKS: Why? How can you even have future ones (unless debugging with time panel)?
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date <= %@", [NSDate date]];
//    NSArray *pastMoodDiaries = [self.moodDiaries filteredArrayUsingPredicate:predicate];
//
//    for (PXMoodDiary *moodDiary in pastMoodDiaries) {
    for (PXMoodDiary *moodDiary in self.moodDiaries) {
        NSTimeZone *tz = [NSTimeZone timeZoneForMoodDiary:moodDiary];
        NSDate *dateInCurrCall = [moodDiary.date dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezone:tz];
        if (previousDate) {
            NSInteger days = [calendar components:NSCalendarUnitDay fromDate:previousDate toDate:dateInCurrCall options:0].day;
            if (days > 1) _currentStreak = 0;
        }
        _currentStreak++;
        if (self.currentStreak > self.highestStreak) _highestStreak = self.currentStreak;
        previousDate = dateInCurrCall;
    }
}

@end
