//
//  PXGoalReflections.h
//  drinkless
//
//  Created by Edward Warrender on 05/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

@interface PXGoalReflections : NSObject

+ (instancetype)loadGoalReflections;

@property (strong, nonatomic) NSMutableArray *whatHasWorked;
@property (strong, nonatomic) NSMutableArray *whatHasNotWorked;

- (void)reload;
- (void)save;

@end
