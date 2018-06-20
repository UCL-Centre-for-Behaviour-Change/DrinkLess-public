//
//  PXWeekSummaryViewController.h
//  drinkless
//
//  Created by Edward Warrender on 21/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>
#import "PXWeekSummary.h"

@interface PXWeekSummaryViewController : UIViewController

@property (strong, nonatomic) PXWeekSummary *weekSummary;
@property (strong, nonatomic) NSMutableArray *drinkRecords;

@end
