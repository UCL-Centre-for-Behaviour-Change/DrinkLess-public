//
//  PXTrackerAlcoholFreeView.h
//  drinkless
//
//  Created by Edward Warrender on 08/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface PXTrackerAlcoholFreeView : UIView

@property (weak, nonatomic) IBOutlet UISwitch *toggleSwitch;
@property (nonatomic, getter=isCollapsed) BOOL collapsed;

@end
