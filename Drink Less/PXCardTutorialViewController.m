//
//  PXCardTutorialViewController.m
//  drinkless
//
//  Created by Edward Warrender on 03/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXCardTutorialViewController.h"
#import "PXInstructionViewController.h"
#import "PXGamePreferences.h"
#import "PXGroupsManager.h"

@interface PXCardTutorialViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (strong, nonatomic) NSArray *tutorialPages;
@property (strong, nonatomic) NSMutableArray *viewControllers;
@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (nonatomic, getter = isViewingLastPage) BOOL viewingLastPage;

@end

@implementation PXCardTutorialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Card tutorial";
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

- (NSArray *)tutorialPages {
    if (!_tutorialPages) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"TutorialPages" ofType:@"plist"];
        _tutorialPages = [NSArray arrayWithContentsOfFile:path];
    }
    return _tutorialPages;
}

- (NSMutableArray *)viewControllers {
    if (!_viewControllers) {
        _viewControllers = [[NSMutableArray alloc] initWithCapacity:self.tutorialPages.count];
        
        BOOL isPushTall = [PXGamePreferences isPushTall];
        NSString *pushOrientation = [PXGamePreferences pushOrientation];
        NSString *pullOrientation = [PXGamePreferences pullOrientation];
        
        for (NSDictionary *dictionary in self.tutorialPages) {
            NSString *text = dictionary[@"text"];
            NSString *identifier = dictionary[@"identifier"];
            if ([identifier isEqualToString:@"about"]) {
                text = [NSString stringWithFormat:text, pullOrientation, pushOrientation];
            } else if ([identifier isEqualToString:@"away"]) {
                text = [NSString stringWithFormat:text, pushOrientation];
            } else if ([identifier isEqualToString:@"toward"]) {
                text = [NSString stringWithFormat:text, pullOrientation];
            }
            BOOL demo = [dictionary[@"demo"] boolValue];
            PXInstructionViewController *viewController = [PXInstructionViewController instructionWithDemo:demo];
            viewController.tutorialView.landscapePositive = isPushTall;
            viewController.text = text;
            viewController.identifier = dictionary[@"identifier"];
            viewController.cards = dictionary[@"cards"];
            [_viewControllers addObject:viewController];
        }
    }
    return _viewControllers;
}

- (void)setViewingLastPage:(BOOL)viewingLastPage {
    NSString *title = viewingLastPage ? @"Play now!" : @"Next";
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

- (IBAction)pressedDone:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)tappedContinue:(id)sender {
    if (self.isViewingLastPage) {
        [self performSegueWithIdentifier:@"unwindAndPlayGame" sender:nil];
        return;
    }
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
