//
//  PXInfoViewController.m
//  drinkless
//
//  Created by Edward Warrender on 17/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXInfoViewController.h"
#import "PXBlurAnimationController.h"
#import "PXIntroManager.h"
#import "PXGroupsManager.h"

@interface PXInfoViewController () <UIViewControllerTransitioningDelegate, PXBlurAnimationControllerDelegate, UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) NSURL *baseURL;
@property (copy, nonatomic) NSString *html;

@end

@implementation PXInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationBar.shadowImage = [UIImage imageNamed:@"info_shadow"];
    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationBar.topItem.title = self.title;
    
    self.webView.alpha = 0.0;
    [self.webView loadHTMLString:self.html baseURL:self.baseURL];
}

+ (void)showResource:(NSString *)resource fromViewController:(UIViewController *)viewController {
    PXInfoViewController *infoViewController = [[self alloc] initWithResource:resource];
    infoViewController.title = viewController.title ?: viewController.navigationItem.title;
    infoViewController.modalPresentationStyle = UIModalPresentationCustom;
    infoViewController.transitioningDelegate = infoViewController;
    [viewController presentViewController:infoViewController animated:YES completion:nil];
}

- (instancetype)initWithResource:(NSString *)resource {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Info" bundle:nil];
    self = [storyboard instantiateInitialViewController];
    if (self) {
        [self loadResource:resource];
    }
    return self;
}

- (void)loadResource:(NSString *)resource {
    if (!resource) return;
    
    self.baseURL = [[NSBundle mainBundle].bundleURL URLByAppendingPathComponent:@"Info" isDirectory:YES];
    NSString *filename = [resource stringByAppendingPathExtension:@"html"];
    NSURL *url = [self.baseURL URLByAppendingPathComponent:filename];
    NSString *html = [NSMutableString stringWithContentsOfURL:url usedEncoding:nil error:nil];
    html = [html stringByReplacingOccurrencesOfString:@"<html>" withString:@"<html><style>body {background-color: transparent !important};</style>"];
    
    BOOL isFemale = [PXIntroManager sharedManager].gender.boolValue;
    
    if ([resource isEqualToString:@"dashboard"]) {
        BOOL isHigh = [PXGroupsManager sharedManager].highSM.boolValue;
        NSString *replacement = !isHigh ? @"" : @" Tap the words Calories or Money to  see how many calories you've consumed in alcohol and how much you've spent on  it.</p>\n<p>Your Achievements lists how many times in a row you've kept  your diary. You don't have to record drinks to increase your streak, recording  alcohol-free days counts too. This also lists your success against your goals  for the week just gone. Tap any for more detail.";
        html = [NSString stringWithFormat:html, replacement];
    }
    else if ([resource isEqualToString:@"action-plans"]) {
        BOOL isHigh = [PXGroupsManager sharedManager].highAP.boolValue;
        NSString *replacement = !isHigh ? @"" : @"<p>To create an action plan tap &lsquo;Create an action plan&rsquo;.</p>\n<p>You can see all your action plans by, funnily enough, tapping the &lsquo;Your action plans&rsquo; link.</p>";
        html = [NSString stringWithFormat:html, replacement];
    }
    else if ([resource isEqualToString:@"goal-edit"]) {
        NSString *units = isFemale ? @"14" : @"14";
        NSString *spending = isFemale ? @"20" : @"20";
        NSString *calories = isFemale ? @"1100" : @"1100";
        html = [NSString stringWithFormat:html, units, spending, calories];
    }
    else if ([resource isEqualToString:@"your-hangover-and-you"]) {
        NSString *units = isFemale ? @"6" : @"6";
        html = [NSString stringWithFormat:html, units];
    }
    self.html = html;
    self.screenName = [@"Info: " stringByAppendingString:resource];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return [PXBlurAnimationController animationControllerPresenting:YES delegate:self];
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return [PXBlurAnimationController animationControllerPresenting:NO delegate:self];
}

#pragma mark - PXBlurAnimationControllerDelegate

- (void)animationControllerDidCaptureScreenshot:(UIImage *)screenshot {
    self.backgroundImageView.image = screenshot;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    if (!url.isFileURL) {
        [[UIApplication sharedApplication] openURL:url];
        return NO;
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIView animateWithDuration:0.3 animations:^{
        self.webView.alpha = 1.0;
    }];
}

#pragma mark - Actions

- (IBAction)pressedClose:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
