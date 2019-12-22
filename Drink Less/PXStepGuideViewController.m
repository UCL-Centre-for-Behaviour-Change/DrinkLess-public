//
//  PXStepGuideViewController.m
//  drinkless
//
//  Created by Edward Warrender on 15/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXStepGuideViewController.h"
#import "PXStepGuideCell.h"
#import "PXStepGuide.h"
#import "PXTabBarController.h"

@interface PXStepGuideViewController ()

@property (strong, nonatomic) PXStepGuide *stepGuide;

@end

@implementation PXStepGuideViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.stepGuide = [[PXStepGuide alloc] init];
    
    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_8_0) {
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = 44.0;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    BOOL hasFinished;
    NSMutableArray *indexes = [self.stepGuide checkForNewlyCompletedSteps:&hasFinished];
    UIApplication *sharedApplication = [UIApplication sharedApplication];
    [sharedApplication beginIgnoringInteractionEvents];
    
    [self animateStepsAtIndexes:indexes completion:^{
        [sharedApplication endIgnoringInteractionEvents];
        if (hasFinished) [PXStepGuide markAsDone];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (IBAction)pressedSkip:(id)sender {
    [PXStepGuide markAsDone];
}

#pragma mark - Animation

- (void)animateStepsAtIndexes:(NSMutableArray *)indexes completion:(void (^)(void))completion {
    NSNumber *index = indexes.firstObject;
    if (!index && completion) {
        completion();
        return;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index.integerValue inSection:0];
    PXStepGuideCell *cell = (PXStepGuideCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    [UIView transitionWithView:cell duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [UIView performWithoutAnimation:^{
            cell.vivid = YES;
        }];
    } completion:^(BOOL finished) {
        [UIView transitionWithView:cell duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [UIView performWithoutAnimation:^{
                cell.vivid = NO;
                cell.completed = YES;
            }];
        } completion:^(BOOL finished) {
            [indexes removeObjectAtIndex:0];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC * 200), dispatch_get_main_queue(), ^{
                [self animateStepsAtIndexes:indexes completion:completion];
            });
        }];
    }];
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 10.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.self.stepGuide.steps.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PXStep *step = self.stepGuide.steps[indexPath.row];
    PXStepGuideCell *cell = [tableView dequeueReusableCellWithIdentifier:@"stepCell"];
    cell.pictureImageView.image = step.image;
    cell.titleLabel.text = [NSString stringWithFormat:@"%li. %@", (long)indexPath.row + 1, step.title];
    cell.detailLabel.text = step.detail;
    cell.completed = step.hasCompleted;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PXStep *step = self.stepGuide.steps[indexPath.row];
    NSString *identifier = step.identifier;
    PXTabBarController *tabBarController = (PXTabBarController *)self.tabBarController;
    
    if ([identifier isEqualToString:@"goal"]) {
        [tabBarController selectTabAtIndex:1 storyboardName:@"Activities" pushViewControllersWithIdentifiers:@[@"PXGoalsNavTVC", @"PXYourGoalsVC"]];
    }
    else if ([identifier isEqualToString:@"drinks"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PXShowDrinksPanelNotification object:nil];
    }
    else if ([identifier isEqualToString:@"explore"]) {
        tabBarController.selectedIndex = 3;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
