//
//  NSTimeZone+DrinkLess.h
//  drinkless
//
//  Created by Hari Karam Singh on 18/04/2018.
//  Copyright © 2018 Greg Plumbly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PXDrinkRecord.h"
#import "PXAlcoholFreeRecord.h"

@interface NSTimeZone (DrinkLess)

+ (void)registerAppDefaultTimeZone:(NSString *)timeZoneName;
+ (NSTimeZone *)appDefaultTimeZone;

+ (NSTimeZone *)timeZoneForDrinkRecord:(PXDrinkRecord *)record;
+ (NSTimeZone *)timeZoneForAlcoholFreeRecord:(PXAlcoholFreeRecord *)record;


@end
