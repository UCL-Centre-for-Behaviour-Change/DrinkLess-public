//
//  PXDateStepControl.h
//  drinkless
//
//  Created by Edward Warrender on 13/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface PXDateStepControl : UIControl

@property (strong, nonatomic) NSDate *date;
@property (nonatomic) BOOL allowsFutureDates;
@property (nonatomic) BOOL allowsPastDates;

- (void)decrease;
- (void)increase;

@end
