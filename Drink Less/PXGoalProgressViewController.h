//
//  PXGoalProgressViewController.h
//  drinkless
//
//  Created by Edward Warrender on 23/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@class PXGoal;

@interface PXGoalProgressViewController : PXTrackedViewController

- (instancetype)initWithGoal:(PXGoal *)goal;

@end
