//
//  PXTipView.m
//  drinkless
//
//  Created by Artsiom Khitryk on 4/4/16.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXTipView.h"

static NSString *const PXShowingScreenCountKey = @"PXShowingScreenCountKey";

@interface PXTipView()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topYConstraint;

@end

@implementation PXTipView

- (void)showTipToConstant:(NSInteger)constant {
    

    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *showingScreenCount = [userDefaults valueForKey:PXShowingScreenCountKey];
    NSInteger incrementCount = [showingScreenCount integerValue] + 1;
    [userDefaults setObject:@(incrementCount) forKey:PXShowingScreenCountKey];
    [userDefaults synchronize];
        
    if ([showingScreenCount integerValue] == 0 ||
        [showingScreenCount integerValue] == 2 ||
        [showingScreenCount integerValue] == 9 ||
        [showingScreenCount integerValue] == 19) {
        
        [UIView animateWithDuration:1 animations:^{
            
            self.topYConstraint.constant = constant;
            [self layoutIfNeeded];
            
        } completion:^(BOOL finished) {
            
            [UIView animateWithDuration:1 delay:5 options:0 animations:^{
                
                self.topYConstraint.constant = self.topYConstraint.constant - self.frame.size.height;
                [self layoutIfNeeded];
                
            } completion:nil];
        }];
    }
}

@end
