//
//  PXEditGoalViewController.h
//  drinkless
//
//  Created by Edward Warrender on 27/01/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@class PXGoal;

@interface PXEditGoalViewController : UITableViewController

@property (strong, nonatomic) PXGoal *referenceGoal;
@property (nonatomic) BOOL isOnboarding;

@end
