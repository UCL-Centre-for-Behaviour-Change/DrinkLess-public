//
//  PXIdentityMemoReminderVC.h
//  drinkless
//
//  Created by Chris on 29/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>
#import "PXMemoManager.h"

@interface PXIdentityMemoReminderVC : UITableViewController

@property (nonatomic) PXMemoReminderType memoReminderType;
@property (weak, nonatomic) PXMemoReminder *existingReminder;

@end
