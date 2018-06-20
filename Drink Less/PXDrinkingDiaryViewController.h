//
//  PXDrinkingRecordsViewController.h
//  drinkless
//
//  Created by Edward Warrender on 11/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface PXDrinkingDiaryViewController : PXTrackedViewController

@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) NSDate *date;

@end
