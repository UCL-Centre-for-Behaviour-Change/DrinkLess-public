//
//  PXGamePreferences.m
//  drinkless
//
//  Created by Edward Warrender on 27/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXGamePreferences.h"
#import <Parse/Parse.h>

static NSString *const PXThankNoThanksRulesKey = @"thankNoThanksRules";
static NSString *const PXLandscape = @"landscape";
static NSString *const PXPortrait = @"portrait";

@implementation PXGamePreferences

+ (BOOL)isPushTall {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults objectForKey:PXThankNoThanksRulesKey]) {
        BOOL pushTall = arc4random_uniform(2);
        [userDefaults setObject:@(pushTall) forKey:PXThankNoThanksRulesKey];
        [userDefaults synchronize];
        
        PFUser *currentUser = [PFUser currentUser];
        currentUser[PXThankNoThanksRulesKey] = pushTall ? @"pushTall-pullWide" : @"pushWide-pushTall";
        [currentUser saveInBackground];
        return pushTall;
    }
    return [[userDefaults objectForKey:PXThankNoThanksRulesKey] boolValue];
}

+ (NSString *)pushOrientation {
    return [self isPushTall] ? PXPortrait : PXLandscape;
}

+ (NSString *)pullOrientation {
    return [self isPushTall] ? PXLandscape : PXPortrait;
}

@end
