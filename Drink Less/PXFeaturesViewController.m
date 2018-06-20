//
//  PXFeaturesViewController.m
//  Drink Less
//
//  Created by Edward Warrender on 17/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXFeaturesViewController.h"

@implementation PXFeaturesViewController

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Center the table vertically if the content size height has changed
    CGFloat height = self.tableView.contentSize.height;
    CGFloat verticalSpace = self.tableView.bounds.size.height - height;
    if (verticalSpace > 0) {
        self.tableView.contentInset = UIEdgeInsetsMake(verticalSpace * 0.5, 0.0, 0.0, 0.0);
        self.tableView.scrollEnabled = NO;
    } else {
        self.tableView.contentInset = UIEdgeInsetsZero;
        self.tableView.scrollEnabled = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [PXTrackedViewController trackScreenName:@"Features"];
}

@end
