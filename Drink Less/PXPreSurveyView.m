//
//  PXPreSurveyView.m
//  drinkless
//
//  Created by Brio Taliaferro on 27/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXPreSurveyView.h"

@implementation PXPreSurveyView

- (void)awakeFromNib {
    [self.tapGesture addTarget:self action:@selector(cancelTextField)];
}

- (void)cancelTextField {
    [self.drinksNumberTextField resignFirstResponder];
}

- (IBAction)takeTestTapped:(UIButton *)sender {

    
    if ([self.delegate respondsToSelector:@selector(preSurveyView:dismissedWithNumberOfDrinks:intoxicationLevel:)]) {
        [self.delegate preSurveyView:self
         dismissedWithNumberOfDrinks:self.drinksNumberTextField.text.intValue intoxicationLevel:self.intoxicationSlider.value];
    }
}

@end
