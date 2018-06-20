//
//  PXEditActionPlanViewController.h
//  drinkless
//
//  Created by Edward Warrender on 16/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@class PXActionPlan;

@protocol PXEditActionPlanViewControllerDelegate;

@interface PXEditActionPlanViewController : UITableViewController

@property (copy, nonatomic) PXActionPlan *actionPlan;
@property (weak, nonatomic) id <PXEditActionPlanViewControllerDelegate> delegate;

@end

@protocol PXEditActionPlanViewControllerDelegate <NSObject>

- (void)didFinishEditing:(PXEditActionPlanViewController *)editActionPlanViewController;
- (void)didCancelEditing:(PXEditActionPlanViewController *)editActionPlanViewController;

@end
