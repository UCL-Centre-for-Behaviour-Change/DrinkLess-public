//
//  PXGamePreferences.m
//  drinkless
//
//  Created by Edward Warrender on 27/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXGamePreferences.h"
#import "drinkless-Swift.h"

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
        
        [DataServer.shared saveUserParameters:@{PXThankNoThanksRulesKey: pushTall ? @"pushTall-pullWide" : @"pushWide-pushTall"} callback:nil];
        
        return pushTall;
    }
    return [[userDefaults objectForKey:PXThankNoThanksRulesKey] boolValue];
}

+ (NSString *)pushOrientation {
    return [self isPushTall] ? PXPortrait : PXLandscape;
}
+ (NSString *)pushParenthetical {
    return [self isPushTall] ? @"(long and thin)" : @"(short and wide)";
}

+ (NSString *)pullOrientation {
    return [self isPushTall] ? PXLandscape : PXPortrait;
}
+ (NSString *)pullParenthetical {
    return ![self isPushTall] ? @"(long and thin)" : @"(short and wide)";
}


@end
