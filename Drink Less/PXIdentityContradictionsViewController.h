//
//  PXIdentityContradictionsViewController.h
//  drinkless
//
//  Created by Edward Warrender on 05/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>
@class PXUserIdentity;

@interface PXIdentityContradictionsViewController : PXTrackedViewController    

@property (strong, nonatomic) PXUserIdentity *userIdentity;

@end
