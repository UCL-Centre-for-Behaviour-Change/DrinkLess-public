//
//  NSTimeZone+DrinkLess.h
//  drinkless
//
//  Created by Hari Karam Singh on 18/04/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PXDrinkRecord;
@class PXAlcoholFreeRecord;
@class PXGoal;
@class PXMoodDiary;

@interface NSTimeZone (DrinkLess)

+ (void)registerAppDefaultTimeZone:(NSString *)timeZoneName;
+ (NSTimeZone *)appDefaultTimeZone;

/** @TODO DRY and smarten this up perhaps when converting to Swift  */
+ (NSTimeZone *)timeZoneForDrinkRecord:(PXDrinkRecord *)record;
+ (NSTimeZone *)timeZoneForAlcoholFreeRecord:(PXAlcoholFreeRecord *)record;
+ (NSTimeZone *)timeZoneForGoal:(PXGoal *)goal;
+ (NSTimeZone *)timeZoneForMoodDiary:(PXMoodDiary *)moodDiary;


@end
