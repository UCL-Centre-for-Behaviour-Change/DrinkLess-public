//
//  PXInstructionViewController.h
//  drinkless
//
//  Created by Edward Warrender on 03/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>
#import "PXTutorialView.h"

@interface PXInstructionViewController : PXTrackedViewController

+ (instancetype)instructionWithDemo:(BOOL)demo;

@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSArray *cards;
@property (strong, nonatomic, readonly) PXTutorialView *tutorialView;

@end
