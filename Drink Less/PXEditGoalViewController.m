//
//  PXEditGoalViewController.m
//  drinkless
//
//  Created by Edward Warrender on 27/01/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXEditGoalViewController.h"
#import "PXRecordCell.h"
#import "PXGoal+Extras.h"
#import "PXItemListVC.h"
#import "FPPopoverController.h"
#import "PXCoreDataManager.h"
#import "NSManagedObject+PXFindByID.h"
#import "PXGoalCalculator.h"
#import "PXIntroManager.h"
#import "PXInfoViewController.h"
#import "PXUnitsGuideViewController.h"

static CGFloat const PXSpacingHeight = 12.0;
static NSInteger const PXToggleSection = 1;

@interface PXEditGoalViewController () <PXItemListVCDelegate>

@property (weak, nonatomic) IBOutlet PXRecordCell *typeCell;
@property (weak, nonatomic) IBOutlet PXRecordCell *targetMaxCell;
@property (weak, nonatomic) IBOutlet PXRecordCell *toggleCell;
@property (weak, nonatomic) IBOutlet UILabel *guideLabl;
@property (strong, nonatomic) FPPopoverController *popoverVC;
@property (nonatomic, getter = isNewGoal) BOOL newGoal;
@property (nonatomic, getter = shouldStartAsNewGoal) BOOL startAsNewGoal;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) PXGoal *goal;
@property (strong, nonatomic) NSNumber *defaultTarget;

@end

@implementation PXEditGoalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.context = [PXCoreDataManager temporaryContext];
    self.newGoal = (self.refenceGoal == nil);
    
    self.title = self.isNewGoal ? @"Set goal" : @"Change goal";
    self.tableView.rowHeight = 44.0; // Required on iOS 8
    
    if (self.isNewGoal) {
        self.goal = (PXGoal *)[PXGoal createInContext:self.context];
        self.goal.goalType = @(PXGoalTypeUnits);
        self.goal.startDate = [NSDate startOfThisWeek];
    } else {
        self.refenceGoal = (PXGoal *)[self.context objectWithID:self.refenceGoal.objectID];
        self.goal = [self.refenceGoal copyGoalIntoContext:self.context];
    }
    
    self.typeCell.valueLabel.text = self.goal.goalTypeTitle;
    
    NSString *toggleTitle = self.isNewGoal ? @"Recurring" : @"Start as new goal";
    self.toggleCell.titleLabel.text = toggleTitle;
    NSString *toggleImageName = self.isNewGoal ? @"Icon-Recur" : @"Icon-New";
    self.toggleCell.iconImage = [UIImage imageNamed:toggleImageName];
    
    if (self.isNewGoal) {
        self.toggleCell.toggleSwitch.on = self.goal.recurring.boolValue;
    } else {
        self.toggleCell.toggleSwitch.on = NO;
    }

    if (self.isNewGoal) {
        [self updateDefaults];
    } else {
        [self reloadMaxTarget];
    }
    
    [self showUnitGiude];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [PXTrackedViewController trackScreenName:@"Edit goals"];
}

#pragma mark - Defaults

- (NSNumber *)calculateDefaultTarget {
    BOOL isFemale = [PXIntroManager sharedManager].gender.boolValue;
    
    switch (self.goal.goalType.integerValue) {
        case PXGoalTypeUnits:
            return isFemale ? @14 : @14;
        case PXGoalTypeFreeDays:
            return @3;
        case PXGoalTypeCalories:
            return isFemale ? @1100 : @1100;
    }
    return @0;
}

- (void)updateDefaults {
    self.defaultTarget = [self calculateDefaultTarget];
}

#pragma mark - Properties

- (void)setDefaultTarget:(NSNumber *)defaultTarget {
    if (![_defaultTarget isEqualToNumber:defaultTarget]) {
        _defaultTarget = defaultTarget;
        self.goal.targetMax = defaultTarget;
        [self reloadMaxTarget];
    }
}

- (void)setStartAsNewGoal:(BOOL)startAsNewGoal {
    _startAsNewGoal = startAsNewGoal;
    
    self.goal.startDate = startAsNewGoal ? [NSDate startOfThisWeek] : self.refenceGoal.startDate;
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == PXToggleSection && self.shouldStartAsNewGoal) {
        return @"Editing ends this goal and starts a new one. The graphs that show your progress wouldn't work otherwise";
    }
    return [super tableView:tableView titleForFooterInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 40.0;
        case 1:
            return 48.0 - PXSpacingHeight;
        case 2:
            return PXSpacingHeight;
        default:
            return [super tableView:tableView heightForHeaderInSection:section];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == PXToggleSection && self.shouldStartAsNewGoal) {
        return [super tableView:tableView heightForFooterInSection:section];
    }
    return PXSpacingHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView endEditing:YES];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell == self.typeCell) {
        [self showList:[PXGoal allGoalTypeTitles].allValues
                object:self.goal.goalTypeTitle
         fromIndexPath:indexPath];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - Actions

- (IBAction)showInfo:(id)sender {
    [PXInfoViewController showResource:@"goal-edit" fromViewController:self];
}

- (IBAction)toggledSwitch:(UISwitch *)sender {
    if (sender == self.toggleCell.toggleSwitch && !self.isNewGoal) {
        self.startAsNewGoal = sender.isOn;
    }
}

- (IBAction)pressedSave:(id)sender {
    [self performSegueWithIdentifier:@"save" sender:nil];
}

- (IBAction)pressedUnitsButton:(id)sender {
    
    [self presentViewController:[PXUnitsGuideViewController navigationController] animated:YES completion:nil];
}

- (void)reloadMaxTarget {
    PXGoalType goalType = self.goal.goalType.integerValue;
    BOOL hasTextField = (goalType == PXGoalTypeCalories ||
                         goalType == PXGoalTypeSpending);
    self.targetMaxCell.textField.hidden = !hasTextField;
    self.targetMaxCell.quantityControl.hidden = hasTextField;
    
    if (hasTextField) {
        self.targetMaxCell.formatType = (goalType == PXGoalTypeSpending) ? PXFormatTypeCurrency : PXFormatTypeInteger;
        self.targetMaxCell.textField.text = [self.targetMaxCell.numberFieldDelegate.numberFormatter stringFromNumber:self.goal.targetMax];
    } else {
        self.targetMaxCell.quantityControl.value = self.goal.targetMax.integerValue;
    }
}

- (void)showList:(NSArray *)list object:(NSObject *)object fromIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    PXItemListVC *itemListVC = [[PXItemListVC alloc] initWithNibName:@"PXItemListVC" bundle:nil];
    itemListVC.itemsArray = list;
    itemListVC.selectedIndex = [list indexOfObject:object];
    itemListVC.sectionIndex = indexPath.section;
    itemListVC.delegate = self;
    
    CGFloat height = (list.count + 1) * self.tableView.rowHeight;
    CGFloat maxHeight = self.tableView.rowHeight * 5;
    if (height > maxHeight) {
        height = maxHeight;
    }
    [self showPopoverWithViewController:itemListVC fromView:cell size:CGSizeMake(240.0, height)];
}

- (void)showPopoverWithViewController:(UIViewController *)viewController fromView:(UIView *)view size:(CGSize)size {
    self.popoverVC = [[FPPopoverController alloc] initWithViewController:viewController];
    self.popoverVC.border = NO;
    self.popoverVC.tint = FPPopoverPureWhiteTint;
    self.popoverVC.contentSize = size;
    [self.popoverVC setShadowsHidden:YES];
    [self.popoverVC presentPopoverFromView:view];
}

- (void)showUnitGiude {
    
    if (self.goal.goalType.integerValue != PXGoalTypeUnits) {
        
        self.guideLabl.text = @"";
        return;
    }
    
    self.guideLabl.text = [NSMutableString stringWithFormat:@"Click here for a guide to the number of units in common drinks."];
    
    NSRange range = [self.guideLabl.text rangeOfString:@"Click here" options:NSCaseInsensitiveSearch];
    if (range.location != NSNotFound) {
        NSDictionary *linkAttributes = @{NSForegroundColorAttributeName: [UIColor drinkLessGreenColor],
                                         NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:self.guideLabl.text];
        [attributedText addAttributes:linkAttributes range:range];
        self.guideLabl.attributedText = attributedText;
    }
}

#pragma mark - PXItemListVCDelegate

- (void)itemListVC:(PXItemListVC *)itemListVC chosenIndex:(NSInteger)chosenIndex {
    NSString *object = itemListVC.itemsArray[chosenIndex];
    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell == self.typeCell) {
        NSNumber *type = [[PXGoal allGoalTypeTitles] allKeysForObject:object].firstObject;
        self.goal.goalType = type;
        self.typeCell.valueLabel.text = object;
        [self reloadMaxTarget];
        [self updateDefaults];
    }
    [self.popoverVC dismissPopoverAnimated:YES];
    
    [self showUnitGiude];
}

#pragma mark - Saving

- (void)updateGoal {
    PXGoalType goalType = self.goal.goalType.integerValue;
    BOOL hasTextField = (goalType == PXGoalTypeCalories ||
                         goalType == PXGoalTypeSpending);
    if (hasTextField) {
        self.goal.targetMax = [self.targetMaxCell.numberFieldDelegate.numberFormatter numberFromString:self.targetMaxCell.textField.text];
    } else {
        self.goal.targetMax = @(self.targetMaxCell.quantityControl.value);
    }
    if (self.isNewGoal) {
        self.goal.recurring = @(self.toggleCell.toggleSwitch.isOn);
    }
    if (!self.goal.recurring.boolValue) {
        self.goal.endDate = self.goal.calculatedEndDate;
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [self.view endEditing:YES];
    
    if ([segue.identifier isEqualToString:@"save"]) {
        [self updateGoal];
        
        if (self.shouldStartAsNewGoal) {
            // Ending reference goal and making new copy a different record on parse
            self.refenceGoal.endDate = self.goal.startDate;
            [self.refenceGoal saveToParse];
            self.goal.parseObjectId = nil;
            self.goal.parseUpdated = @NO;
        }
        else if (!self.isNewGoal) {
            // Replacing reference goal with an updated copy
            [self.context deleteObject:self.refenceGoal];
        }
        [self.context save:nil];
        [self.goal saveToParse];
    }
}

@end
