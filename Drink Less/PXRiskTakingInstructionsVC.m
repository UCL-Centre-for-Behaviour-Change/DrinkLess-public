//
//  PXRiskTaskingInstructionsVC.m
//  drinkless
//
//  Created by Greg Plumbly on 10/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXRiskTakingInstructionsVC.h"

@interface PXRiskTakingInstructionsVC ()

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation PXRiskTakingInstructionsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.textView.textContainer.lineFragmentPadding = 15.0;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Center the text vertically if the height has changed
    // Calculate textView height instead of using content size as it doesn't work correctly
    CGFloat height = [self.textView sizeThatFits:CGSizeMake(self.textView.frame.size.width, MAXFLOAT)].height;
    CGFloat verticalSpace = self.textView.bounds.size.height - height;
    if (verticalSpace > 0) {
        self.textView.contentInset = UIEdgeInsetsMake(verticalSpace * 0.5, 0.0, 0.0, 0.0);
    } else {
        self.textView.contentInset = UIEdgeInsetsZero;
    }
}

@end
