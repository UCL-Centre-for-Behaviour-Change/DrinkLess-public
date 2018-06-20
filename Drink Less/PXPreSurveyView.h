//
//  PXPreSurveyView.h
//  drinkless
//
//  Created by Brio Taliaferro on 27/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@class PXPreSurveyView;

@protocol PXPreSurveyViewDelegate <NSObject>

- (void)preSurveyView:(PXPreSurveyView*)preSurveyView dismissedWithNumberOfDrinks:(int)numberOfDrinks intoxicationLevel:(float)intoxication;

@end

@interface PXPreSurveyView : UIView

@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UITextField *drinksNumberTextField;
@property (weak, nonatomic) IBOutlet UISlider *intoxicationSlider;
@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *tapGesture;

@property (weak, nonatomic) id <PXPreSurveyViewDelegate> delegate;

@end
