//
//  PXIdentityIntroViewController.m
//  drinkless
//
//  Created by Edward Warrender on 02/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXIdentityIntroViewController.h"
#import "PXUserIdentity.h"
#import "PXIdentityPhotoViewController.h"

@interface PXIdentityIntroViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation PXIdentityIntroViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"I am";
    self.screenName = @"Identity intro";
    
    self.textView.textContainer.lineFragmentPadding = 15.0;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.userIdentity.seenIntro = YES; // this was NO ??
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.userIdentity save];
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
    if ([segue.identifier isEqualToString:@"showPhoto"]) {
        PXIdentityPhotoViewController *photoVC = segue.destinationViewController;
        photoVC.userIdentity = self.userIdentity;
    }
}

@end
