//
//  PXYourGoalsViewController.m
//  drinkless
//
//  Created by Edward Warrender on 27/01/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXYourGoalsViewController.h"
#import "PXGoalCell.h"
#import "PXEditGoalViewController.h"
#import "PXGoal+Extras.h"
#import "PXCoreDataManager.h"
#import "PXGoalProgressViewController.h"
#import "PXGoalStatistics.h"
#import "PXGroupsManager.h"
#import <AVFoundation/AVFoundation.h>
#import "TSMessageView.h"
#import "PXStepGuide.h"
#import "PXInfoViewController.h"
#import "PXUnitsGuideViewController.h"
#import "PXTipView.h"

static NSString *const PXGoalCellIdentifier = @"goalCell";

@interface PXYourGoalsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) PXTipView *tipView;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) NSMutableArray *goals;
@property (strong, nonatomic) NSMutableArray *goalsStatistics;
@property (nonatomic, getter = isShowingActiveGoals) BOOL showActiveGoals;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@end

@implementation PXYourGoalsViewController

+ (void)initialize
{
#if RESET_SCREENS_VIEWED_COUNT_FOR_TIP
    [userDefaults setObject:@(0) forKey:PXShowingScreenCountKey];
    [userDefaults synchronize];
#endif

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Your goals";
    
    [self.tableView registerNib:[PXGoalCell nib] forCellReuseIdentifier:PXGoalCellIdentifier];
    self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItem, self.editButtonItem];
    self.context = [PXCoreDataManager sharedManager].managedObjectContext;
    
    self.tipView = [[PXTipView alloc] initWithFrame:CGRectMake(0, -43, self.view.frame.size.width, 43)];
    [self.view addSubview:self.tipView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Init audio only if enabled
    self.audioPlayer = nil;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enable-sounds"]) {
        NSURL *audioURL = [[NSBundle mainBundle] URLForResource:@"DrinkSuccess" withExtension:@"wav"];
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.audioPlayer prepareToPlay];
        });
    }
    
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

#pragma mark - Calculate

- (void)reloadData {
    NSManagedObjectModel *model = self.context.persistentStoreCoordinator.managedObjectModel;
    NSDictionary *variables = @{@"EMPTY": [NSNull null], @"TODAY": [NSDate strictDateFromToday]};
    NSString *template = self.isShowingActiveGoals ? @"activeGoals" : @"previousGoals";
    NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:template substitutionVariables:variables];
    fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:NO]];
    self.goals = [self.context executeFetchRequest:fetchRequest error:nil].mutableCopy;
    
    self.goalsStatistics = [NSMutableArray arrayWithCapacity:self.goals.count];
    for (PXGoal *goal in self.goals) {
        PXGoalStatistics *goalStatistics = [[PXGoalStatistics alloc] initWithGoal:goal region:PXStatisticRegionLastCompleted];
        [self.goalsStatistics addObject:goalStatistics];
    }
    [self.tableView reloadData];
}

#pragma mark - Properties

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    [self.tableView setEditing:editing animated:animated];
}

- (void)setShowActiveGoals:(BOOL)showActiveGoals {
    NSInteger index = showActiveGoals ? 0 : 1;
    self.segmentedControl.selectedSegmentIndex = index;
}

- (BOOL)isShowingActiveGoals {
    return self.segmentedControl.selectedSegmentIndex == 0;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"editGoal"]) {
        PXEditGoalViewController *editGoalVC = segue.destinationViewController;
        NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
        editGoalVC.refenceGoal = self.goals[indexPath.row];
    }
}

- (IBAction)unwindToYourGoals:(UIStoryboardSegue *)segue {
    if ([segue.identifier isEqualToString:@"save"]) {
        PXEditGoalViewController *editGoalVC = segue.sourceViewController;
        if (!editGoalVC.refenceGoal) {
            [TSMessage showNotificationInViewController:self
                                                  title:@"Well done on setting a new goal"
                                               subtitle:nil
                                                   type:TSMessageNotificationTypeSuccess
                                               duration:2.0];
            // Delay sound by 0.4 seconds to sync with TSMessage
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC * 400), dispatch_get_main_queue(), ^{
                self.audioPlayer.currentTime = 0;
                [self.audioPlayer play];
            });
            
            [PXStepGuide completeStepWithID:@"goal"];
        }
    }
}

- (void)pressedInfoButton:(id)sender {
    
    [self presentViewController:[PXUnitsGuideViewController navigationController] animated:YES completion:nil];
}

#pragma mark - Actions

- (IBAction)segmentedControlChanged:(id)sender {
    [self reloadData];
}

- (IBAction)showInfo:(id)sender {
    NSString *resource = self.isShowingActiveGoals ? @"goals-active" : @"goals-previous";
    [PXInfoViewController showResource:resource fromViewController:self];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.goals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PXGoalCell *cell = [tableView dequeueReusableCellWithIdentifier:PXGoalCellIdentifier];
    PXGoal *goal = self.goals[indexPath.row];
    cell.titleLabel.text = goal.title;
    cell.subtitleLabel.text = goal.overview;
    if (![PXGroupsManager sharedManager].highSM.boolValue)
        cell.accessoryType = UITableViewCellAccessoryNone;

    PXGoalStatistics *goalStatistics = self.goalsStatistics[indexPath.row];
    PXGoalStatus status = [goalStatistics.data[PXStatusKey] integerValue];
    cell.iconImageView.image = [PXGoalCalculator imageForGoalStatus:status thumbnail:YES];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (self.isShowingActiveGoals) {
        BOOL isHigh = [PXGroupsManager sharedManager].highSM.boolValue;
        return [NSString stringWithFormat:@"Good goals are specific and a little challenging. Not too challenging though, because often the hardest thing about making a change is sticking with it. So it's important to keep your goals realistic. You can alter them at any time if you find they're too difficult or too easy%@.", isHigh ? @" and we'll give you feedback about your rates of goal success to help you set goals you can keep hitting" : @""];
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    
 //   UILabel *headerLabel = [[UILabel alloc]init];
    
    
    CGRect footerFrame = [tableView rectForFooterInSection:0];
    CGRect labelFrame = CGRectMake(20, 20, footerFrame.size.width - 40, footerFrame.size.height - 10);
    
    UIView *footer = [[UIView alloc] initWithFrame:footerFrame];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:labelFrame];
    

    if (self.isShowingActiveGoals) {
        BOOL isHigh = [PXGroupsManager sharedManager].highSM.boolValue;
        
        if (isHigh) {
        headerLabel.text = @"Good goals are specific and a little challenging. Not too challenging though, because often the hardest thing about making a change is sticking with it. So it's important to keep your goals realistic. You can alter them at any time if you find they're too difficult or too easy and we'll give you feedback about your rates of goal success to help you set goals you can keep hitting.";
        } else {
        headerLabel.text = @"Good goals are specific and a little challenging. Not too challenging though, because often the hardest thing about making a change is sticking with it. So it's important to keep your goals realistic. You can alter them at any time if you find they're too difficult or too easy.";
        
        }
    }
    
    headerLabel.numberOfLines = 0 ;
  //  [headerLabel sizeToFit];
    headerLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17.0];
    headerLabel.textColor = [UIColor darkGrayColor];
    headerLabel.backgroundColor = [UIColor clearColor];
    
    [footer addSubview:headerLabel];
    return footer;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return  200;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        PXGoal *goal = self.goals[indexPath.row];
        if (self.isShowingActiveGoals) {
            goal.endDate = [NSDate strictDateFromToday];
            [goal saveToParse];
        } else {
            [self.context deleteObject:goal];
            [goal deleteFromParse];
        }
        [self.context save:nil];
        
        [self.goals removeObjectAtIndex:indexPath.row];
        [self.goalsStatistics removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.isShowingActiveGoals) {
        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"Delete" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [tableView.dataSource tableView:tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
        }];
        NSMutableArray *editActions = @[deleteAction].mutableCopy;
        
        PXGoal *goal = self.goals[indexPath.row];
        if (goal.isRestorable) {
            __weak typeof(self) weakSelf = self;
            UITableViewRowAction *activateAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Activate" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                PXGoal *goal = weakSelf.goals[indexPath.row];
                if (goal.recurring.boolValue) {
                    goal.endDate = nil;
                } else {
                    goal.endDate = goal.calculatedEndDate;
                }
                [weakSelf.context save:nil];
                [goal saveToParse];
                
                [weakSelf.goals removeObjectAtIndex:indexPath.row];
                [weakSelf.goalsStatistics removeObjectAtIndex:indexPath.row];
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
            }];
            [editActions addObject:activateAction];
        }
        return editActions;
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 15.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing) {
        [self performSegueWithIdentifier:@"editGoal" sender:nil];
    } else {
        if (![PXGroupsManager sharedManager].highSM.boolValue) {
         
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
        }
        PXGoal *goal = self.goals[indexPath.row];
        PXGoalProgressViewController *goalProgressVC = [[PXGoalProgressViewController alloc] initWithGoal:goal];
        [self.navigationController pushViewController:goalProgressVC animated:YES];
    }
}

@end
