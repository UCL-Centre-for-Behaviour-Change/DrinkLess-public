//
//  PXEditFlipsideViewController.h
//  drinkless
//
//  Created by Edward Warrender on 12/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@class PXFlipside;

@protocol PXEditFlipsideViewControllerDelegate;

@interface PXEditFlipsideViewController : PXTrackedViewController

@property (copy, nonatomic) PXFlipside *flipside;
@property (weak, nonatomic) id <PXEditFlipsideViewControllerDelegate> delegate;

@end

@protocol PXEditFlipsideViewControllerDelegate <NSObject>

- (void)didFinishEditing:(PXEditFlipsideViewController *)editFlipsideViewController;
- (void)didCancelEditing:(PXEditFlipsideViewController *)editFlipsideViewController;

@end
