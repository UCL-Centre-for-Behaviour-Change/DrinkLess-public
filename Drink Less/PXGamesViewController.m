//
//  PXGamesViewController.m
//  drinkless
//
//  Created by Edward Warrender on 05/11/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXGamesViewController.h"

@implementation PXGamesViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    
    if (self.navItemsArray.count == 1) {
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:self.storyboardName bundle:nil];
        NSDictionary *dict = self.navItemsArray.firstObject;
        NSString *identifier = dict[@"vc"];
        UIViewController *viewController = [storyBoard instantiateViewControllerWithIdentifier:identifier];
        self.navigationController.viewControllers = @[viewController];
    }
}

@end
