//
//  PXTrackedViewController.h
//  drinkless
//
//  Created by Edward Warrender on 15/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface PXTrackedViewController : UIViewController

+ (void)trackScreenName:(NSString *)screenName;

@property (nonatomic, copy) NSString *screenName;

@end
