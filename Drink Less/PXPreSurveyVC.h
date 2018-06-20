//
//  PXPreSurveyVC.h
//  drinkless
//
//  Created by Brio Taliaferro on 27/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@protocol PXPreSurveyProtocol <NSObject>

- (void)setSurveyType:(NSString*)surveyType;
- (void)setNumberOfDrinks:(int)numberOfDrinks;
- (void)setIntoxication:(float)intoxication;

@end

@interface PXPreSurveyVC : UIViewController

@property (nonatomic, strong) NSString *surveyType;

@end
