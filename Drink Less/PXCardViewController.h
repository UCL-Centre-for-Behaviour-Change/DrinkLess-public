//
//  PXCardViewController.h
//  Cards
//
//  Created by Edward Warrender on 02/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@class PXUserGameHistory;

@interface PXCardViewController : PXTrackedViewController

@property (strong, nonatomic) PXUserGameHistory *userGameHistory;

@end

