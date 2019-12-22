//
//  NSDateComponents+DrinkLess.m
//  drinkless
//
//  Created by Hari Karam Singh on 18/04/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

#import "NSDateComponents+DrinkLess.h"

@implementation NSDateComponents (DrinkLess)

- (NSComparisonResult)compare:(NSDateComponents *)dateComps
{
    if (self.year < dateComps.year) return NSOrderedAscending;
    if (self.year > dateComps.year) return NSOrderedDescending;
    if (self.month < dateComps.month) return NSOrderedAscending;
    if (self.month > dateComps.month) return NSOrderedDescending;
    if (self.day < dateComps.day) return NSOrderedAscending;
    if (self.day > dateComps.day) return NSOrderedDescending;
    
    return NSOrderedSame;    
}

@end
