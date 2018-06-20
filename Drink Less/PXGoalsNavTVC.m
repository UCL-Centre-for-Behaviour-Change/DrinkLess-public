//
//  PXGoalsNavTVC.m
//  drinkless
//
//  Created by Brio Taliaferro on 11/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXGoalsNavTVC.h"
#import "PXGoalsHeader.h"
#import "UIViewController+PXHelpers.h"

@interface PXGoalsNavTVC ()

@property (weak, nonatomic) IBOutlet PXGoalsHeader *goalsHeader;

@end

@implementation PXGoalsNavTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Goals";
    self.navigationItem.rightBarButtonItem = nil;
    
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"PXGoalsSubNav" ofType:@"plist"];
    self.navItemsArray = [[NSArray alloc] initWithContentsOfFile:filepath];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.goalsHeader animateAppearance];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    [self checkAndShowTipIfNeeded];
}

@end
