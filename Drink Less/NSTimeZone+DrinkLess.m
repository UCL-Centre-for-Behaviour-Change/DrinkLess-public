//
//  NSTimeZone+DrinkLess.m
//  drinkless
//
//  Created by Hari Karam Singh on 18/04/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

#import "NSTimeZone+DrinkLess.h"
#import "PXDebug.h"
#import "PXDrinkRecord.h"
#import "PXAlcoholFreeRecord.h"
#import "PXGoal.h"
#import "PXMoodDiary.h"

@implementation NSTimeZone (DrinkLess)

+ (void)registerAppDefaultTimeZone:(NSString *)timeZoneName
{
    logd(@"registerAppDefaultTimeZone: Storing App Default timezone (for legacy records): %@", timeZoneName);
    [NSUserDefaults.standardUserDefaults setObject:timeZoneName forKey:@"drinkless.appDefaultTimeZone"];
    [NSUserDefaults.standardUserDefaults synchronize];
}

//---------------------------------------------------------------------

+ (NSTimeZone *)appDefaultTimeZone
{
    // Keep this once off grab of the current TZ in case we change back to that. But this is a UK app so I think just having London is better. They might be travelling when this is grabbed and the old way would register their default time zone to their holiday destination's
    NSString *tzName = [NSUserDefaults.standardUserDefaults objectForKey:@"drinkless.appDefaultTimeZone"];
    if (!tzName) {
        tzName = NSTimeZone.systemTimeZone.name;
        [self registerAppDefaultTimeZone:tzName];
    }
//    return [NSTimeZone timeZoneWithName:tzName];
    return [NSTimeZone timeZoneWithName:@"Europe/London"];
}

//---------------------------------------------------------------------

+ (NSTimeZone *)timeZoneForDrinkRecord:(PXDrinkRecord *)record
{
    return [self _timeZoneForRecordWithTimeZoneString:record.timezone];
}

+ (NSTimeZone *)timeZoneForAlcoholFreeRecord:(PXAlcoholFreeRecord *)record
{
    return [self _timeZoneForRecordWithTimeZoneString:record.timezone];
}

+ (NSTimeZone *)timeZoneForGoal:(PXGoal *)goal
{
    return [self _timeZoneForRecordWithTimeZoneString:goal.timezone];
}
+ (NSTimeZone *)timeZoneForMoodDiary:(PXMoodDiary *)moodDiary
{
    return [self _timeZoneForRecordWithTimeZoneString:moodDiary.timezone];
}
+ (NSTimeZone *)_timeZoneForRecordWithTimeZoneString:(NSString *)timeZoneStr
{
    NSTimeZone *recTimezone = [NSTimeZone timeZoneWithName:timeZoneStr];
    if (!recTimezone) {
        recTimezone = [NSTimeZone appDefaultTimeZone];
    }
    return recTimezone;
}

@end
