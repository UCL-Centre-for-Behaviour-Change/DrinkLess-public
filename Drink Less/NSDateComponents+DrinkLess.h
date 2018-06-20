//
//  NSDateComponents+DrinkLess.h
//  drinkless
//
//  Created by Hari Karam Singh on 18/04/2018.
//  Copyright © 2018 Greg Plumbly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDateComponents (DrinkLess)

// Just compares the day, month, year for our needs
- (NSComparisonResult)compare:(NSDateComponents *)dateComps;

@end
