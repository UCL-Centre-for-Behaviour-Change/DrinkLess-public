//
//  PXIntroNavigationController.m
//  Drink Less
//
//  Created by Chris on 08/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXIntroNavigationController.h"

@interface PXIntroNavigationController ()

@end

@implementation PXIntroNavigationController

- (void)awakeFromNib {
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showProgressToolbar) name:@"PXShowProgressToolbar" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideProgressToolbar) name:@"PXHideProgressToolbar" object:nil];
}

- (void)showProgressToolbar {
    [self setToolbarHidden:NO animated:YES];
}

- (void)hideProgressToolbar {
    [self setToolbarHidden:YES animated:YES];
}

@end
