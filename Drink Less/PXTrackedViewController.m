//
//  PXTrackedViewController.m
//  drinkless
//
//  Created by Edward Warrender on 15/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXTrackedViewController.h"
#import <Google/Analytics.h>
#import <Parse/Parse.h>
#import "UIViewController+PXHelpers.h"

@interface PXTrackedViewController()


@end

@implementation PXTrackedViewController

+ (void)trackScreenName:(NSString *)screenName {
    if (screenName) {
        [self googleLogScreenName:screenName];
        [self parseLogScreenName:screenName];
    }
}

+ (void)googleLogScreenName:(NSString *)screenName {
    id tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:screenName];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

+ (void)parseLogScreenName:(NSString *)screenName {
    PFObject *object = [PFObject objectWithClassName:@"PXScreenView"];
    object[@"user"] = [PFUser currentUser];
    object[@"name"] = screenName;
    [object saveEventually];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.class trackScreenName:self.screenName];
    
    [self checkAndShowTipIfNeeded];
}

@end
