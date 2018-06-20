//
//  PXUserActionPlans.h
//  drinkless
//
//  Created by Edward Warrender on 16/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

@interface PXUserActionPlans : NSObject <NSCoding>

+ (instancetype)loadActionPlans;

@property (strong, nonatomic) NSMutableArray *actionPlans;

- (void)save;

@end
