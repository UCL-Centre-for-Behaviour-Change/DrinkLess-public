//
//  PXHowAlcoholEffectsViewController.m
//  drinkless
//
//  Created by Greg Plumbly on 31/01/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXHowAlcoholEffectsViewController.h"
#import "PXAlcoholEffects.h"
#import "PXTabView.h"
#import "PXAlcoholEffectViewController.h"
#import "PXPlaceholderViewRenamed.h"
#import "PXDailyTaskManager.h"
#import "UIViewController+Swipe.h"
#import "PXInfoViewController.h"

@interface PXHowAlcoholEffectsViewController ()

@property (strong, nonatomic) PXAlcoholEffects *alcoholEffects;
@property (strong, nonatomic) NSMutableArray *viewControllers;
@property (weak, nonatomic) IBOutlet PXTabView *tabView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet PXPlaceholderViewRenamed *placeholderView;

@end

@implementation PXHowAlcoholEffectsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.placeholderView setImage:[UIImage imageNamed:@"no_graph"]
                             title:@"No Mood Diaries"
                          subtitle:@"You have not recorded any mood diaries.\n\nTo record a mood diary, go to the Dashboard and tap on “Logging your drinks and mood” under 'We suggest'."
                            footer:nil];
    
    self.screenName = @"How alcohol effects";
    
    __weak typeof(self) weakSelf = self;
    [self addSwipeWithCallback:^(UISwipeGestureRecognizerDirection direction) {
        if (direction == UISwipeGestureRecognizerDirectionLeft) {
            if (weakSelf.tabView.selectedIndex < weakSelf.tabView.titles.count - 1) {
                weakSelf.tabView.selectedIndex++;
            }
            [weakSelf tabValueChanged:weakSelf.tabView];
        } else if (direction == UISwipeGestureRecognizerDirectionRight) {
            if (weakSelf.tabView.selectedIndex > 0) {
                weakSelf.tabView.selectedIndex--;
            }
            [weakSelf tabValueChanged:weakSelf.tabView];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.alcoholEffects = [[PXAlcoholEffects alloc] init];
    BOOL hasData = (self.alcoholEffects != nil);
    if (hasData) {
        self.tabView.titles = [self.alcoholEffects.information valueForKey:@"title"];
        
        for (UIViewController *viewController in self.viewControllers) {
            if ([viewController isKindOfClass:[PXAlcoholEffectViewController class]]) {
                PXAlcoholEffectViewController *alcoholEffectVC = (PXAlcoholEffectViewController *)viewController;
                alcoholEffectVC.alcoholEffects = self.alcoholEffects;
            }
        }
        [self showViewController:self.viewControllers[self.tabView.selectedIndex]];
    }
    self.containerView.hidden = !hasData;
    self.tabView.hidden = !hasData;
    self.placeholderView.hidden = hasData;
    
    [[PXDailyTaskManager sharedManager] completeTaskWithID:@"review-drinking"];
    [[PXDailyTaskManager sharedManager] completeTaskWithID:@"alcohol-effects"];
}

- (void)showViewController:(UIViewController *)newViewController {
    UIViewController *oldViewController = self.childViewControllers.firstObject;
    if (oldViewController) {
        [oldViewController willMoveToParentViewController:nil];
        [oldViewController.view removeFromSuperview];
        [oldViewController removeFromParentViewController];
    }
    [self addChildViewController:newViewController];
    newViewController.view.frame = self.containerView.bounds;
    [self.containerView addSubview:newViewController.view];
    [newViewController didMoveToParentViewController:self];
}

#pragma mark - Actions

- (IBAction)tabValueChanged:(PXTabView *)tabView {
    [self showViewController:self.viewControllers[tabView.selectedIndex]];
}

- (IBAction)showInfo:(id)sender {
    [PXInfoViewController showResource:@"your-hangover-and-you" fromViewController:self];
}

#pragma mark - Properties

- (NSMutableArray *)viewControllers {
    if (!_viewControllers) {
        NSInteger effectsCount = self.alcoholEffects.information.count;
        _viewControllers = [NSMutableArray arrayWithCapacity:effectsCount];
        for (NSInteger i = 0; i < effectsCount; i++) {
            PXAlcoholEffectViewController *alcoholEffectVC = [[PXAlcoholEffectViewController alloc] initWithEffectType:i];
            [alcoholEffectVC view]; // Getter to invoke viewDidLoad
            [_viewControllers addObject:alcoholEffectVC];
        }
    }
    return _viewControllers;
}

@end
