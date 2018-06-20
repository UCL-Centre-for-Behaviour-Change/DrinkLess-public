//
//  PXGoalReflectionsViewController.m
//  drinkless
//
//  Created by Edward Warrender on 04/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXGoalReflectionsViewController.h"
#import "PXBulletCell.h"
#import "PXGoalReflections.h"
#import "PXGroupsManager.h"
#import "PXInfoViewController.h"
#import "UIViewController+PXHelpers.h"

static NSString *const PXAchievedKey = @"achieved";
static NSString *const PXTitleKey = @"title";
static NSString *const PXReasonsKey = @"reasons";
static NSString *const PXBulletCellIdentifier = @"bulletCell";

@interface PXGoalReflectionsViewController () <PXBulletCellDelegate>

@property (strong, nonatomic) NSArray *list;
@property (strong, nonatomic) PXGoalReflections *goalReflections;

@end

@implementation PXGoalReflectionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItem, self.editButtonItem];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.goalReflections = [PXGoalReflections loadGoalReflections];
    self.list = @[@{PXAchievedKey: @YES,
                    PXTitleKey   : @"What worked:",
                    PXReasonsKey : self.goalReflections.whatHasWorked},
                  @{PXAchievedKey: @NO,
                    PXTitleKey   : @"What didn't work:",
                    PXReasonsKey : self.goalReflections.whatHasNotWorked}];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [PXTrackedViewController trackScreenName:@"Goal reflections"];
    
    [self checkAndShowTipIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.goalReflections save];
}

#pragma mark - Actions

- (void)viewActionPlans {
    UINavigationController *navigationController = self.navigationController;
    [navigationController popViewControllerAnimated:NO];
    UIViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PXActionPlansViewController"];
    [navigationController pushViewController:viewController animated:NO];
}

- (IBAction)showInfo:(id)sender {
    [PXInfoViewController showResource:@"has-and-hasnt-worked" fromViewController:self];
}

#pragma mark - Convenience

- (BOOL)isSectionAchieved:(NSInteger)section {
    return [self.list[section][PXAchievedKey] boolValue];
}

- (UIColor *)colorForSection:(NSInteger)section {
    return [self isSectionAchieved:section] ? [UIColor drinkLessGreenColor] : [UIColor goalRedColor];
}

- (void)configureCell:(PXBulletCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.textView.text = self.list[indexPath.section][PXReasonsKey][indexPath.row];
    cell.dotColor = [self colorForSection:indexPath.section];
}

#pragma mark - PXBulletCellDelegate

- (void)insertLine:(NSString *)line fromCell:(PXBulletCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSMutableArray *reasons = self.list[indexPath.section][PXReasonsKey];
    
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
    [reasons insertObject:line atIndex:newIndexPath.row];
    [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    [self.tableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
    PXBulletCell *newCell = (PXBulletCell *)[self.tableView cellForRowAtIndexPath:newIndexPath];
    [newCell.textView becomeFirstResponder];
    newCell.textView.selectedRange = NSMakeRange(0, 0);
}

- (void)deleteLine:(NSString *)line fromCell:(PXBulletCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSInteger numberOfRows = [self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:indexPath.section];
    // Can't delete the last one
    if (indexPath.row == 0 && numberOfRows < 2) {
        return;
    }
    NSInteger indexShift = (indexPath.row == 0) ? 1 : -1;
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row + indexShift inSection:indexPath.section];
    [self.tableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
    PXBulletCell *newCell = (PXBulletCell *)[self.tableView cellForRowAtIndexPath:newIndexPath];
    
    NSUInteger location = newCell.textView.text.length;
    NSMutableArray *reasons = self.list[indexPath.section][PXReasonsKey];
    NSString *text = [NSString stringWithFormat:@"%@%@", newCell.textView.text, line];
    reasons[newIndexPath.row] = text;
    newCell.textView.text = text;
    [newCell.textView becomeFirstResponder];
    newCell.textView.selectedRange = NSMakeRange(location, 0);
    
    [reasons removeObjectAtIndex:indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)changedTextViewInCell:(PXBulletCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    self.list[indexPath.section][PXReasonsKey][indexPath.row] = cell.textView.text;
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.list.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.list[section][PXReasonsKey] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PXBulletCell *cell = [tableView dequeueReusableCellWithIdentifier:PXBulletCellIdentifier forIndexPath:indexPath];
    [self configureCell:cell forRowAtIndexPath:indexPath];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.list[section][PXTitleKey];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
        headerView.textLabel.font = [UIFont systemFontOfSize:16.0];
        headerView.textLabel.text = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
        headerView.textLabel.textColor = [self colorForSection:section];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    PXBulletCell *cell = [tableView dequeueReusableCellWithIdentifier:PXBulletCellIdentifier];
    cell.bounds = tableView.bounds;
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    [self configureCell:cell forRowAtIndexPath:indexPath];
    CGFloat height = [cell.textView sizeThatFits:CGSizeMake(cell.textView.bounds.size.width, CGFLOAT_MAX)].height;
    return height;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == tableView.numberOfSections - 1 && [PXGroupsManager sharedManager].highAP.boolValue) {
        return @"If you’re having difficulty a plan for how to deal with difficult drinking situations might help";
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UITableViewHeaderFooterView *)view forSection:(NSInteger)section {
    NSString *text = [tableView.dataSource tableView:tableView titleForFooterInSection:section];
    NSRange range = [text rangeOfString:@"a plan" options:NSCaseInsensitiveSearch];
    if (range.location != NSNotFound) {
        NSDictionary *linkAttributes = @{NSForegroundColorAttributeName: [UIColor drinkLessGreenColor],
                                         NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:view.textLabel.text];
        [attributedText addAttributes:linkAttributes range:range];
        view.textLabel.attributedText = attributedText;
        
        if (view.gestureRecognizers.count == 0) {
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewActionPlans)];
            [view addGestureRecognizer:tapGesture];
        }
    } else {
        for (UIGestureRecognizer *gestureRecognizer in view.gestureRecognizers) {
            [view removeGestureRecognizer:gestureRecognizer];
        }
    }
}

#pragma mark - UITableViewDelegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    // Disallow moving if there is only one cell left in the section
    BOOL isLastCell = [tableView.dataSource tableView:tableView numberOfRowsInSection:sourceIndexPath.section] < 2;
    return isLastCell ? sourceIndexPath : proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSMutableArray *fromReasons = self.list[fromIndexPath.section][PXReasonsKey];
    NSString *reason = fromReasons[fromIndexPath.row];
    [fromReasons removeObjectAtIndex:fromIndexPath.row];
    
    NSMutableArray *toReasons = self.list[toIndexPath.section][PXReasonsKey];
    [toReasons insertObject:reason atIndex:toIndexPath.row];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [tableView beginUpdates];
        PXBulletCell *cell = (PXBulletCell *)[tableView cellForRowAtIndexPath:toIndexPath];
        [self configureCell:cell forRowAtIndexPath:toIndexPath];
        [tableView endUpdates];
    });
}

@end
