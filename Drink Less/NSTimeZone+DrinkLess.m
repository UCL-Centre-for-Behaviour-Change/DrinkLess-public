//
//  NSTimeZone+DrinkLess.m
//  drinkless
//
//  Created by Hari Karam Singh on 18/04/2018.
//  Copyright © 2018 Greg Plumbly. All rights reserved.
//

#import "NSTimeZone+DrinkLess.h"
#import "PXDebug.h"

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
    NSString *tzName = [NSUserDefaults.standardUserDefaults objectForKey:@"drinkless.appDefaultTimeZone"];
    if (!tzName) {
        tzName = NSTimeZone.systemTimeZone.name;
        [self registerAppDefaultTimeZone:tzName];
    }
    return [NSTimeZone timeZoneWithName:tzName];
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
+ (NSTimeZone *)_timeZoneForRecordWithTimeZoneString:(NSString *)timeZoneStr
{
    NSTimeZone *recTimezone = [NSTimeZone timeZoneWithName:timeZoneStr];
    if (!recTimezone) {
        recTimezone = [NSTimeZone appDefaultTimeZone];
    }
    return recTimezone;
}

@end
