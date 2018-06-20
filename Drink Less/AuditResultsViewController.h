//
//  AuditResultsViewController.h
//  Drink Less
//
//  Created by Greg Plumbly on 29/08/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface AuditResultsViewController : UIViewController

+ (instancetype)auditResultsViewController;

@property (nonatomic, getter = isButtonContainerHidden) BOOL buttonContainerHidden;

@end
