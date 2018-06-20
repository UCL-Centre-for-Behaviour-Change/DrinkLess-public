//
//  PXLowGroupAuditViewController.m
//  drinkless
//
//  Created by Edward Warrender on 22/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXLowGroupAuditViewController.h"

@interface PXLowGroupAuditViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic) CGFloat contentHeight;

@end

@implementation PXLowGroupAuditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Low group audit";
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"AlcoholAdvice" ofType:@"html"];
    NSString *advice = [NSString stringWithContentsOfFile:path usedEncoding:nil error:nil];
    [self.webView loadHTMLString:advice baseURL:[NSBundle mainBundle].bundleURL];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Center the webview vertically if the content size height has changed
    CGFloat verticalSpace = self.webView.bounds.size.height - self.contentHeight;
    if (verticalSpace > 0) {
        self.webView.scrollView.contentInset = UIEdgeInsetsMake(verticalSpace * 0.5, 0.0, 0.0, 0.0);
        self.webView.scrollView.scrollEnabled = NO;
    } else {
        self.webView.scrollView.contentInset = UIEdgeInsetsZero;
        self.webView.scrollView.scrollEnabled = YES;
    }
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.contentHeight = [webView stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight;"].floatValue;
    [self.view setNeedsLayout];
}

@end
