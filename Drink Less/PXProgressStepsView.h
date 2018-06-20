//
//  PXProgressStepsView.h
//  drinkless
//
//  Created by Edward Warrender on 20/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface PXProgressStepsView : UIView

@property (strong, nonatomic) NSArray *steps;
@property (nonatomic) NSInteger currentStep;

@end
