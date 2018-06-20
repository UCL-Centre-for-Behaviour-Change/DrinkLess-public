//
//  PXSensationQuestionCell.h
//  drinkless
//
//  Created by Brio Taliaferro on 27/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>
#import "PXSurveyTextField.h"

@interface PXSurveyQuestionCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *questionLabel;
@property (weak, nonatomic) IBOutlet PXSurveyTextField *answerTextField;


@end
