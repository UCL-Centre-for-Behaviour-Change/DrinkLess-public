//
//  PXRiskTakingViewController.h
//  drinkless
//
//  Created by Edward Warrender on 18/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface PXRiskTakingViewController : PXTrackedViewController

@property (nonatomic, strong) NSString *surveyType;
@property (nonatomic) int numberOfDrinks;
@property (nonatomic) float intoxication;

@end

