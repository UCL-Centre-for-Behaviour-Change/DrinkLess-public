//
//  PXCardResultsViewController.h
//  drinkless
//
//  Created by Edward Warrender on 11/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@class PXUserGameHistory, PXCardGameLog;

@interface PXCardResultsViewController : PXTrackedViewController

@property (strong, nonatomic) PXUserGameHistory *userGameHistory;
@property (strong, nonatomic) PXCardGameLog *gameLog;

@end
