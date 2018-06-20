//
//  PXIdentityAspectsViewController.h
//  drinkless
//
//  Created by Edward Warrender on 02/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@class PXUserIdentity;

@interface PXIdentityAspectsViewController : PXTrackedViewController

@property (strong, nonatomic) PXUserIdentity *userIdentity;

@end
