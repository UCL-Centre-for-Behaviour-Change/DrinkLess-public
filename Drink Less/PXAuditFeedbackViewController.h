//
//  PXAuditFeedbackViewController.h
//  drinkless
//
//  Created by Edward Warrender on 22/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>
#import "PXTrackedViewController.h"

@interface PXAuditFeedbackViewController : PXTrackedViewController

+ (instancetype)auditFeedbackViewController;

@property (nonatomic, getter = isButtonContainerHidden) BOOL buttonContainerHidden;

@end
