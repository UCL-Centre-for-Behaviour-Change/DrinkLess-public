//
//  PXFlipsidesIntroViewController.m
//  drinkless
//
//  Created by Edward Warrender on 02/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXFlipsidesIntroViewController.h"
#import "PXUserFlipsides.h"
#import "PXFlipsidesViewController.h"

@interface PXFlipsidesIntroViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation PXFlipsidesIntroViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Flipsides intro";
    
    self.textView.textContainer.lineFragmentPadding = 15.0;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.userFlipsides.seenIntro = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.userFlipsides save];
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

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showFlipsides"]) {
        PXFlipsidesViewController *flipsidesVC = segue.destinationViewController;
        flipsidesVC.userFlipsides = self.userFlipsides;
    }
}

@end
