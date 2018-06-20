//
//  PXSensationSeekingTVC.h
//  drinkless
//
//  Created by Brio Taliaferro on 27/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>
#import "PXPreSurveyVC.h"

@interface PXSurveyTVC : UITableViewController <PXPreSurveyProtocol>

@property (nonatomic, strong) NSString* surveyType;
@property (nonatomic) int numberOfDrinks;
@property (nonatomic) float intoxication;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;

@end
