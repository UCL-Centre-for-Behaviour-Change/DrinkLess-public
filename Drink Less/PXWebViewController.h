//
//  PXWebViewController.h
//  drinkless
//
//  Created by Edward Warrender on 10/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface PXWebViewController : PXTrackedViewController

- (instancetype)initWithResource:(NSString *)resource;

@property (nonatomic, copy) IBInspectable NSString *resource;
@property (nonatomic) IBInspectable BOOL openedOutsideOnboarding;

@end
