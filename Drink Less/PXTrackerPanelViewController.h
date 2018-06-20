//
//  PXTrackerPanelViewController.h
//  drinkless
//
//  Created by Edward Warrender on 05/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@protocol PXTrackerPanelViewControllerDelegate;

@interface PXTrackerPanelViewController : PXTrackedViewController

+ (instancetype)viewController;

@property (weak, nonatomic) id <PXTrackerPanelViewControllerDelegate> delegate;
@property (strong, nonatomic) UIImage *backgroundImage;
@property (strong, nonatomic) NSDate *referenceDate;
@property (nonatomic, getter=isDatePicking) BOOL datePicking;

- (void)setOpen:(BOOL)open animated:(BOOL)animated completion:(void (^)(void))completion;

@end

@protocol PXTrackerPanelViewControllerDelegate <NSObject>

- (void)shouldClosePanel;

- (void)didCompleteCloseAfterDrag;

@end

@protocol PXTrackerPanelChild <NSObject>

@property (weak, nonatomic) PXTrackerPanelViewController *panelViewController;
@property (strong, nonatomic) NSDate *referenceDate;

@end

