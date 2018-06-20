//
//  PXCardMenuViewController.m
//  drinkless
//
//  Created by Edward Warrender on 03/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXCardMenuViewController.h"
#import "PXGroupsManager.h"
#import "PXUserGameHistory.h"
#import "PXStepGuide.h"
#import "PXInfoViewController.h"
#import "PXTipView.h"

@interface PXCardMenuViewController ()

@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) PXUserGameHistory *userGameHistory;
@property (weak, nonatomic) IBOutlet UITableViewCell *previousScoresCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *retrainingMindCell;
@property (retain, nonatomic) IBOutlet PXTipView *tipView;
@property (nonatomic, readonly) BOOL isHigh;

@end

@implementation PXCardMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _isHigh = [PXGroupsManager sharedManager].highAAT.boolValue;
    
    self.headerView = self.tableView.tableHeaderView;
    self.userGameHistory = [PXUserGameHistory loadGameHistory];

    UIButton *infoBtn = [UIButton buttonWithType:UIButtonTypeInfoDark];
    [infoBtn addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithCustomView:infoBtn];
    // Make the info button to the right of help. Also safeguard against nil
    NSArray *barButtonItems = [@[barItem] arrayByAddingObjectsFromArray:(self.navigationItem.rightBarButtonItems?:@[])];
    self.navigationItem.rightBarButtonItems = barButtonItems;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [PXTrackedViewController trackScreenName:@"Card menu"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tableView.tableHeaderView = self.isHigh ? self.headerView : nil;
    [self.tableView reloadData];
    
    [self.tipView showTipToConstant:40];
    
    //    special case when "explore" will be completed
    //    https://github.com/PortablePixels/DrinkLess/issues/187
    if ([[PXStepGuide loadCompletedSteps] count] == 2) {
        
        [PXStepGuide completeStepWithID:@"explore"];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (cell == self.previousScoresCell && self.userGameHistory.cardGameLogs.count < 2) {
        return 0;
    } else if (cell == self.retrainingMindCell && !self.isHigh) {
        return 0;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController respondsToSelector:@selector(userGameHistory)]) {
        [segue.destinationViewController setUserGameHistory:self.userGameHistory];
    }
    [PXStepGuide completeStepWithID:@"explore"];
}

- (IBAction)unwindToCardMenu:(UIStoryboardSegue *)segue {
    if ([segue.identifier isEqualToString:@"unwindAndPlayGame"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"playGame" sender:nil];
        });
    }
}

- (void)showInfo {
    NSString *resource = self.isHigh ? @"game-high" : @"game-low";
    [PXInfoViewController showResource:resource fromViewController:self];
}


@end
