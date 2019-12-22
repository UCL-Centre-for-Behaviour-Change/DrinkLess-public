//
//  PXHighGroupAuditViewController.m
//  drinkless
//
//  Created by Edward Warrender on 22/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXHighGroupAuditViewController.h"
#import "PXInfographicViewController.h"
#import "PXWebViewController.h"
#import "drinkless-Swift.h"

@interface PXHighGroupAuditViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (strong, nonatomic) NSMutableArray *viewControllers;
@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonContainerConstraint;
@property (nonatomic) CGFloat originalButtonContainerHeight;
@property (nonatomic, getter = isViewingLastPage) BOOL viewingLastPage;
@property (strong, nonatomic) PXAuditFeedbackHelper *helper;
@property (nonatomic) BOOL isOnboarding;

@end

@implementation PXHighGroupAuditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"High group audit view";
    self.originalButtonContainerHeight = self.buttonContainerConstraint.constant;
    self.buttonContainerHidden = self.isButtonContainerHidden;
}

- (void)_setup {
    self.isOnboarding = VCInjector.shared.isOnboarding;
    if (!self.helper) { // See below
        self.helper = [[PXAuditFeedbackHelper alloc] initWithDemographicData:VCInjector.shared.demographicData];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"embedPageVC"]) {
        UIPageViewController *pageViewController = segue.destinationViewController;
        pageViewController.dataSource = self;
        pageViewController.delegate = self;
        [pageViewController setViewControllers:@[self.viewControllers.firstObject]
                                     direction:UIPageViewControllerNavigationDirectionForward
                                      animated:NO
                                    completion:NULL];
        self.viewingLastPage = NO;
        self.pageViewController = pageViewController;
    }
}

#pragma mark - Properties

- (NSMutableArray *)viewControllers {
    [self _setup];
    
    if (!_viewControllers) {
        NSUInteger count = 4;
        _viewControllers = [[NSMutableArray alloc] initWithCapacity:count];
        for (NSUInteger i = 0; i < count; i++) {
            PXGraphicType graphicType = (i % 2) ? PXGraphicTypePeople : PXGraphicTypeGauge;
            PXInfographicViewController *infographicViewController = [PXInfographicViewController infographicWithType:graphicType];
            infographicViewController.populationType = (i < 2) ? PopulationTypeCountry : PopulationTypeDemographic;
            infographicViewController.helper = self.helper;
            [_viewControllers addObject:infographicViewController];
        }
        
        // Skip the verbage for re-audits
        if (self.isOnboarding) {
            PXWebViewController *introViewController = [[PXWebViewController alloc] initWithResource:@"audit-feedback-intro"];
            [_viewControllers insertObject:introViewController atIndex:0];
            
            PXWebViewController *outroViewController = [[PXWebViewController alloc] initWithResource:@"audit-feedback-outro"];
            [_viewControllers addObject:outroViewController];
        }
    }
    return _viewControllers;
}

- (void)setButtonContainerHidden:(BOOL)buttonContainerHidden {
    _buttonContainerHidden = buttonContainerHidden;
    
    if (self.isViewLoaded) {
        self.buttonContainerConstraint.constant = buttonContainerHidden ? 0 : self.originalButtonContainerHeight;
    }
}

- (void)setViewingLastPage:(BOOL)viewingLastPage {
    
    NSString *buttonTxtForLast = self.isOnboarding ? @"Continue" : @"Finish";
    NSString *title = viewingLastPage ? buttonTxtForLast : @"Next";
    [self.continueButton setTitle:title forState:UIControlStateNormal];
    _viewingLastPage = viewingLastPage;
}

#pragma mark - UIPageViewControllerDataSource

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return self.viewControllers.count;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    UIViewController *viewController = self.pageViewController.viewControllers.firstObject;
    return [self.viewControllers indexOfObject:viewController];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger index = [self.viewControllers indexOfObject:viewController];
    if (index > 0) {
        index--;
        return self.viewControllers[index];
    }
    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger index = [self.viewControllers indexOfObject:viewController];
    if (index < self.viewControllers.count - 1) {
        index++;
        return self.viewControllers[index];
    }
    return nil;
}

#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    NSUInteger index = [self.viewControllers indexOfObject:self.pageViewController.viewControllers.firstObject];
    self.viewingLastPage = (index == self.viewControllers.count - 1);
}

#pragma mark - Actions

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (sender == self.continueButton && self.isViewingLastPage) {
        return NO;
    }
    return [super canPerformAction:action withSender:sender];
}

- (IBAction)tappedContinue:(id)sender {
    __weak typeof(self) weakSelf = self;
    
    NSUInteger index = [self.viewControllers indexOfObject:self.pageViewController.viewControllers.firstObject] + 1;
    [self.pageViewController setViewControllers:@[self.viewControllers[index]]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:YES
                                     completion:^(BOOL finished) {
                                         weakSelf.viewingLastPage = (index == weakSelf.viewControllers.count - 1);
                                     }];
}

@end
