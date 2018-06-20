//
//  PXConsentViewController.m
//  Drink Less
//
//  Created by Edward Warrender on 17/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXConsentViewController.h"
#import "PXIntroManager.h"
#import <Google/Analytics.h>

@interface PXConsentViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (strong, nonatomic) NSArray *viewControllers;
@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (weak, nonatomic) IBOutlet UIButton *consentButton;
@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (nonatomic, getter = isViewingLastPage) BOOL viewingLastPage;
@property (nonatomic, getter = hasConsent) BOOL consent;

@end

@implementation PXConsentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Welcome";
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
        self.pageViewController = pageViewController;
        self.viewingLastPage = NO;
    }
}

- (void)updateButton {
    self.continueButton.enabled = !self.viewingLastPage || self.hasConsent;
}

#pragma mark - Properties

- (NSArray *)viewControllers {
    if (!_viewControllers) {
        NSArray *identifiers = @[@"welcomeVC", @"informationVC"];
        NSMutableArray *viewControllers = [NSMutableArray arrayWithCapacity:identifiers.count];
        for (NSString *identifier in identifiers) {
            [viewControllers addObject:[self.storyboard instantiateViewControllerWithIdentifier:identifier]];
        }
        _viewControllers = viewControllers.copy;
    }
    return _viewControllers;
}

- (void)setViewingLastPage:(BOOL)viewingLastPage {
    _viewingLastPage = viewingLastPage;
    
    self.consentButton.alpha = viewingLastPage;
    [self updateButton];
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

- (IBAction)pressedCheckbox:(UIButton *)button {
    button.selected = !button.selected;
    
    self.consent = !self.consent;
    [self updateButton];
}

- (IBAction)pressedContinueButton:(id)sender {
    self.isViewingLastPage ? [self finish] : [self goToNextPage];
}

- (void)goToNextPage {
    __weak typeof(self) weakSelf = self;
    
    NSUInteger index = [self.viewControllers indexOfObject:self.pageViewController.viewControllers.firstObject] + 1;
    [self.pageViewController setViewControllers:@[self.viewControllers[index]]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:YES
                                     completion:^(BOOL finished) {
                                         weakSelf.viewingLastPage = (index == weakSelf.viewControllers.count - 1);
                                     }];
}

- (void)finish {
    PXIntroManager *introManager = [PXIntroManager sharedManager];
    introManager.stage = PXIntroStageAuditQuestions;
    [introManager save];
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"button_press"     // Event category (required)
                                                          action:@"continue_on_welcome_screen"  // Event action (required)
                                                           label:@"continue"          // Event label
                                                           value:nil] build]];    // Event value
    
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
