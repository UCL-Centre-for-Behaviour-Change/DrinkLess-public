//
//  PXYourActionPlansViewController.m
//  drinkless
//
//  Created by Edward Warrender on 16/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXYourActionPlansViewController.h"
#import "PXUserActionPlans.h"
#import "PXActionPlan.h"
#import "PXEditActionPlanViewController.h"
#import "PXActionPlanCell.h"
#import "PXPlaceholderViewRenamed.h"
#import "PXInfoViewController.h"

@interface PXYourActionPlansViewController () <UITableViewDataSource, UITableViewDelegate, PXEditActionPlanViewControllerDelegate>

@property (weak, nonatomic) IBOutlet PXPlaceholderViewRenamed *placeholderView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSIndexPath *expandedIndexPath;
@property (strong, nonatomic) UIBarButtonItem *rightBarButtonItem;

@end

@implementation PXYourActionPlansViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Your action plans";
    
    self.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
    
    [self.placeholderView setImage:[UIImage imageNamed:@"no_actionplans"]
                             title:@"No Action Plans"
                          subtitle:@"You have not created any action plans."
                            footer:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    BOOL isEmpty = (self.userActionPlans.actionPlans.count == 0);
    self.placeholderView.hidden = !isEmpty;
    self.tableView.hidden = isEmpty;
    self.navigationItem.rightBarButtonItems = isEmpty ? nil : @[self.rightBarButtonItem, self.editButtonItem];
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

#pragma mark - Properties

- (void)setExpandedIndexPath:(NSIndexPath *)expandedIndexPath {
    if (_expandedIndexPath == expandedIndexPath) {
        expandedIndexPath = nil;
    }
    NSIndexPath *oldIndexPath = _expandedIndexPath;
    _expandedIndexPath = expandedIndexPath;
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    
    if (oldIndexPath) { // Collapse old cell
        PXActionPlanCell *cell = (PXActionPlanCell *)[self.tableView cellForRowAtIndexPath:oldIndexPath];
        [cell.actionPlanView setCollapsed:YES animated:YES delay:0.25];
    }
    if (expandedIndexPath) { // Expand new cell
        PXActionPlanCell *cell = (PXActionPlanCell *)[self.tableView cellForRowAtIndexPath:expandedIndexPath];
        [cell.actionPlanView setCollapsed:NO animated:YES delay:0.25];
    }
}

#pragma mark - UITableViewDataSource

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if (self.expandedIndexPath) {
        self.expandedIndexPath = nil;
    }
    [super setEditing:editing animated:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.userActionPlans.actionPlans.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"actionPlanCell" forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        PXActionPlan *actionPlan = self.userActionPlans.actionPlans[indexPath.row];
        [actionPlan deleteFromServer];
        [self.userActionPlans.actionPlans removeObjectAtIndex:indexPath.row];
        [self.userActionPlans save];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isEditing) {
        [self performSegueWithIdentifier:@"editActionPlan" sender:self];
        return;
    }
    self.expandedIndexPath = indexPath;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"actionPlanCell"];
    
    CGRect rect = cell.bounds;
    rect.size.width = tableView.bounds.size.width;
    cell.bounds = rect;
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    [self configureCell:cell forIndexPath:indexPath];
    CGFloat height = [cell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    return height;
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[PXActionPlanCell class]]) {
        PXActionPlan *actionPlan = self.userActionPlans.actionPlans[indexPath.row];
        PXActionPlanCell *actionPlanCell = (PXActionPlanCell *)cell;
        PXActionPlanView *actionPlanView = actionPlanCell.actionPlanView;
        actionPlanView.ifTextLabel.text = actionPlan.ifText;
        actionPlanView.thenTextLabel.text = actionPlan.thenText;
        actionPlanView.collapsed = ![indexPath isEqual:self.expandedIndexPath];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"editActionPlan"]) {
        NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
        PXEditActionPlanViewController *editActionPlanVC = segue.destinationViewController;
        editActionPlanVC.actionPlan = self.userActionPlans.actionPlans[indexPath.row];
        editActionPlanVC.delegate = self;
    }
}

#pragma mark - Actions

- (IBAction)showInfo:(id)sender {
    [PXInfoViewController showResource:@"action-plans-view" fromViewController:self];
}

#pragma mark - PXEditActionPlanViewControllerDelegate

- (void)didCancelEditing:(PXEditActionPlanViewController *)editActionPlanViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didFinishEditing:(PXEditActionPlanViewController *)editActionPlanViewController {
    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    PXActionPlan *actionPlan = editActionPlanViewController.actionPlan;
    [self.userActionPlans.actionPlans replaceObjectAtIndex:indexPath.row withObject:actionPlan];
    [actionPlan saveAndLogToServer:self.userActionPlans];
    [self.navigationController popViewControllerAnimated:YES];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

@end
