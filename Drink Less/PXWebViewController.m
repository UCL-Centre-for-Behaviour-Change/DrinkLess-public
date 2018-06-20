//
//  PXWebViewController.m
//  drinkless
//
//  Created by Edward Warrender on 10/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXWebViewController.h"
#import "PXGroupsManager.h"
#import "PXIntroManager.h"
#import <Parse/Parse.h>

@interface PXWebViewController () <UIWebViewDelegate>

@property (strong, nonatomic) UIWebView *webView;

@end

@implementation PXWebViewController

- (instancetype)initWithResource:(NSString *)resource {
    self = [super init];
    if (self) {
        _openedOutsideOnboarding = NO;
        _resource = resource;
    }
    return self;
}

- (void)viewDidLoad {
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.backgroundColor = [UIColor clearColor];
    self.webView.opaque = NO;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    
    if (self.resource) {
        if ([self.resource isEqualToString:@"action-plans"]) {
            BOOL isHigh = [PXGroupsManager sharedManager].highAP.boolValue;
            self.resource = [self.resource stringByAppendingString:isHigh ? @"-high" : @"-low"];
        }
        
        NSString *path = [[NSBundle mainBundle] pathForResource:self.resource ofType:@"html"];
        NSString *html = [NSString stringWithContentsOfFile:path usedEncoding:nil error:nil];
        
        if ([self.resource isEqualToString:@"good-goal-setting"]) {
            BOOL isHigh = [PXGroupsManager sharedManager].highSM.boolValue;
            NSString *injection = isHigh ? @" and we'll give you feedback about your rates of goal success to help you set goals you can keep hitting" : @"";
            html = [NSString stringWithFormat:html, injection];
        }
        [self.webView loadHTMLString:html baseURL:[NSBundle mainBundle].bundleURL];

        if ([self.resource isEqualToString:@"privacy-policy"]) {
            self.view.tag = 440; // don't show tooltip
            PFUser *currentUser = [PFUser currentUser];
            if (![currentUser[@"acknowledgedPrivacyPolicy"] isEqual: @YES]) {
                UIBarButtonItem *noButton = [[UIBarButtonItem alloc]
                                             initWithTitle:@"No, I disagree"
                                             style:UIBarButtonItemStylePlain
                                             target:self
                                             action:@selector(noTapped:)];
                self.navigationItem.leftBarButtonItem = noButton;

                UIBarButtonItem *yesButton = [[UIBarButtonItem alloc]
                                              initWithTitle:@"Yes, I agree"
                                              style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(yesTapped:)];
                self.navigationItem.rightBarButtonItem = yesButton;
            }
        }
    }
    
    self.screenName = self.title;
    
    [super viewDidLoad];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    if (!url.isFileURL) {
        if ([url.absoluteString isEqualToString:@"app://accept-privacy-policy"]) {
            // accept privacy policy
            [self yesTapped:nil];
            return NO;
        } else if ([url.absoluteString isEqualToString:@"app://decline-privacy-policy"]) {
            [self noTapped:nil];
            return NO;
        } else if ([url.absoluteString isEqualToString:@"app://privacy-notice"]) {
            PXWebViewController *vc = [[PXWebViewController alloc] initWithResource:@"privacy-notice"];
            [vc setOpenedOutsideOnboarding:YES];
            [vc.view setBackgroundColor:[UIColor whiteColor]];
            [self.navigationController pushViewController:vc animated:YES];
            return NO;
        } else {
            [[UIApplication sharedApplication] openURL:url];
            return NO;
        }

    }
    return YES;
}

- (void)closeVC {
    if (self.openedOutsideOnboarding && [self isModal]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if (self.openedOutsideOnboarding) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        PXIntroManager *introManager = [PXIntroManager sharedManager];
        introManager.stage = PXIntroStageAuditQuestions;
        [introManager save];
        [self performSegueWithIdentifier:@"PXShowAuditQuestions" sender:self];
    }
}

- (void)noTapped:(id)sender {
    PFUser *currentUser = [PFUser currentUser];
    currentUser[@"acknowledgedPrivacyPolicy"] = @YES;
    currentUser[@"hasOptedOut"] = @YES;

    [self closeVC];
}

- (void)yesTapped:(id)sender {
    PFUser *currentUser = [PFUser currentUser];
    currentUser[@"acknowledgedPrivacyPolicy"] = @YES;
    currentUser[@"hasOptedOut"] = @NO;

    [currentUser saveEventually];

    [self closeVC];
}

- (BOOL)isModal {
    if([self presentingViewController])
        return YES;
    if([[[self navigationController] presentingViewController] presentedViewController] == [self navigationController])
        return YES;
    if([[[self tabBarController] presentingViewController] isKindOfClass:[UITabBarController class]])
        return YES;

    return NO;
}


@end