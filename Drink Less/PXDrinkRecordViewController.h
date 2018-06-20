//
//  PXDrinkRecordViewController.h
//  drinkless
//
//  Created by Edward Warrender on 06/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@class PXDrinkRecord;

@interface PXDrinkRecordViewController : UITableViewController

+ (PXDrinkRecordViewController *)recordViewController;

@property (strong, nonatomic) PXDrinkRecord *drinkRecord;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (nonatomic, getter = isFavouritesHidden) BOOL hideFavourite;
@property (nonatomic, getter = isAddingDrinkRecord) BOOL addingDrinkRecord;

@end
