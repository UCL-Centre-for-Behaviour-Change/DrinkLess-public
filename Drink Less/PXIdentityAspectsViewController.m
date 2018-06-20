//
//  PXIdentityAspectsViewController.m
//  drinkless
//
//  Created by Edward Warrender on 02/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXIdentityAspectsViewController.h"
#import "PXUserIdentity.h"
#import "PXIdentityContradictionsViewController.h"

static NSString *const PXTitleKey = @"title";
static NSString *const PXIsButtonKey = @"isButton";
static NSString *const PXIsUserCreatedKey = @"isUserCreated";

@interface PXIdentityAspectsViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *aspects;

@end

@implementation PXIdentityAspectsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"I am";
    self.screenName = @"Identity aspects";
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == YES", PXIsUserCreatedKey];
    self.userIdentity.createdAspects = [[self.aspects filteredArrayUsingPredicate:predicate] valueForKey:PXTitleKey];
    [self.userIdentity save];
}

#pragma mark - Properties

- (NSMutableArray *)aspects {
    if (!_aspects) {
        _aspects = @[@{PXTitleKey: @"Important values to me", PXIsButtonKey: @YES}].mutableCopy;
        for (NSString *title in self.userIdentity.createdAspects) {
            [_aspects addObject:@{PXTitleKey: title, PXIsUserCreatedKey: @YES}.mutableCopy];
        }
        for (NSDictionary *dictionary in self.userIdentity.exampleContradictions) {
            [_aspects addObject:@{PXTitleKey: dictionary[PXTitleKey]}];
        }
    }
    return _aspects;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    [self.tableView setEditing:editing animated:animated];
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            [self configureCell:cell atIndexPath:indexPath];
        }
    } completion:NULL];
}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Write a list of the values that are important to you. Or select some of our examples.";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.aspects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"aspectCell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *aspect = self.aspects[indexPath.row];
    NSString *title = aspect[PXTitleKey];
    BOOL isButton = [aspect[PXIsButtonKey] boolValue];
    BOOL isImportant = [self.userIdentity.importantAspects containsObject:title];
    cell.textLabel.textColor = isButton ? self.tableView.tintColor : [UIColor blackColor];
    cell.textLabel.text = title;
    cell.accessoryType = isImportant ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.textLabel.alpha = [self tableView:self.tableView shouldHighlightRowAtIndexPath:indexPath] ? 1.0 : 0.3;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *aspect = self.aspects[indexPath.row];
    BOOL isButton = [aspect[PXIsButtonKey] boolValue];
    BOOL isUserCreated = [aspect[PXIsUserCreatedKey] boolValue];
    return !self.isEditing || isButton || isUserCreated;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *aspect = self.aspects[indexPath.row];
    return [aspect[PXIsUserCreatedKey] boolValue];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.aspects removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *aspect = self.aspects[indexPath.row];
    NSString *title = aspect[PXTitleKey];
    BOOL isButton = [aspect[PXIsButtonKey] boolValue];
    if (isButton || self.isEditing) {
        NSString *message = isButton ? @"Enter attribute name" : @"Edit attribute name";
        NSString *buttonTitle = isButton ? @"Add" : @"Rename";
        NSString *text = isButton ? nil : title;
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:buttonTitle, nil];
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField *textField = [alertView textFieldAtIndex:0];
        textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        textField.text = text;
        [alertView show];
    }
    else {
        BOOL isImportant = [self.userIdentity.importantAspects containsObject:title];
        if (isImportant) {
            [self.userIdentity.importantAspects removeObject:title];
        } else {
            [self.userIdentity.importantAspects addObject:title];
        }
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [self configureCell:cell atIndexPath:indexPath];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *aspect = self.aspects[indexPath.row];
    if (buttonIndex != alertView.cancelButtonIndex) {
        NSString *title = [alertView textFieldAtIndex:0].text;
        for (NSDictionary *aspect in self.aspects) {
            if ([aspect[PXTitleKey] isEqualToString:title]) {
                return; // Already an aspect with this name
            }
        }
        BOOL isButton = [aspect[PXIsButtonKey] boolValue];
        if (isButton) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            indexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
            [self.aspects insertObject:@{PXTitleKey: title, PXIsUserCreatedKey: @YES}.mutableCopy atIndex:indexPath.row];
            [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            self.aspects[indexPath.row][PXTitleKey] = title;
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"showContradictions"]) {
        if (self.userIdentity.importantAspects.count < 1) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please select at least one aspect" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            return NO;
        }
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showContradictions"]) {
        PXIdentityContradictionsViewController *contradictionsVC = segue.destinationViewController;
        contradictionsVC.userIdentity = self.userIdentity;
    }
}

@end
