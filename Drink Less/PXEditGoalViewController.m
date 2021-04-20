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
#import "PXCoreDataManager.h"
#import "NSManagedObject+PXFindByID.h"
#import "PXGoalCalculator.h"
#import "PXIntroManager.h"
#import "PXInfoViewController.h"
#import "PXUnitsGuideViewController.h"
#import "drinkless-Swift.h"

static CGFloat const PXSpacingHeight = 12.0;
static NSInteger const PXDetailsSection = 0;
static NSInteger const PXToggleSection = 1;

@interface PXEditGoalViewController () <PXItemListVCDelegate>

@property (weak, nonatomic) IBOutlet PXRecordCell *typeCell;
@property (weak, nonatomic) IBOutlet PXRecordCell *targetMaxCell;
@property (weak, nonatomic) IBOutlet PXRecordCell *toggleCell;
@property (weak, nonatomic) IBOutlet UILabel *guideLabl;
@property (strong, nonatomic) PopoverVC *popoverVC;
@property (nonatomic, getter = isNewGoal) BOOL newGoal;
@property (nonatomic, getter = shouldStartAsNewGoal) BOOL startAsNewGoal;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) PXGoal *goal;
@property (strong, nonatomic) NSNumber *defaultTarget;
@property (weak, nonatomic) IBOutlet UILabel *introductionLbl;
@property (weak, nonatomic) IBOutlet UIView *introductionView;

@end

@implementation PXEditGoalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.context = [PXCoreDataManager temporaryContext];
    self.newGoal = (self.referenceGoal == nil);
    
    self.title = self.isNewGoal ? @"Set goal" : @"Change goal";
    self.tableView.rowHeight = 44.0; // Required on iOS 8
    
    if (self.isNewGoal) {
        self.goal = (PXGoal *)[PXGoal createInContext:self.context];
        self.goal.goalType = @(PXGoalTypeUnits);
        self.goal.startDate = [NSDate startOfThisWeek];
        self.goal.timezone = NSCalendar.currentCalendar.timeZone.name; // important to use this to grab our swizzle
    } else {
        self.referenceGoal = (PXGoal *)[self.context objectWithID:self.referenceGoal.objectID];
        self.goal = [self.referenceGoal copyGoalIntoContext:self.context];
    }
    
    self.typeCell.valueLabel.text = self.goal.goalTypeTitle;
    self.typeCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-dropdown"]];
    
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


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.isOnboarding) {
        // Clear out the previous VCs
        [self.navigationController setViewControllers:@[self]];
        
        self.introductionLbl.text = @"Creating a goal to work towards will help you drink less. Tap the (i) button above for more information.";
        [self.introductionLbl sizeToFit];

        // Redo the nav bar for onboarding
        UIBarButtonItem *infoBBI = self.navigationItem.rightBarButtonItems[0];
        UIBarButtonItem *skipBBI = [[UIBarButtonItem alloc] initWithTitle:@"Skip" style:UIBarButtonItemStylePlain target:self action:@selector(skipPressed)];
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItems = @[infoBBI, skipBBI];
        self.navigationItem.title = @"Create a Goal";
        //self.navigationItem.rightBarButtonItems
        
    } else {
        self.introductionView.hidden = YES;
        CGRect f = self.introductionView.frame;
        f.size.height = 0;
        self.introductionView.frame = f;
    }
}


//---------------------------------------------------------------------

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [DataServer.shared trackScreenView:@"Edit goals"];
}

#pragma mark - Defaults

- (NSNumber *)calculateDefaultTarget {
//    BOOL isFemale = [PXIntroManager sharedManager].gender.boolValue;
    // if this gets restored then pass it in. don't call a bloody singleton this low down
    
    switch (self.goal.goalType.integerValue) {
        case PXGoalTypeUnits:
//            return isFemale ? @14 : @14;
            return @14;
        case PXGoalTypeFreeDays:
            return @3;
        case PXGoalTypeCalories:
//            return isFemale ? @1100 : @1100;
            return @1100;
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
    
    self.goal.startDate = startAsNewGoal ? [NSDate startOfThisWeek] : self.referenceGoal.startDate;
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == PXToggleSection && self.shouldStartAsNewGoal) {
        return @"Editing ends this goal and starts a new one. The graphs that show your progress wouldn't work otherwise";
    }
    
    if (section == PXDetailsSection) {
        if ([self.typeCell.valueLabel.text isEqualToString:@"Units"]) {
            return @"We’ve suggested 14 units which is the recommended weekly limit. Read the drinking guidelines in full here.\n";
        } else if ([self.typeCell.valueLabel.text isEqualToString:@"Calories"]) {
            return @"We’ve suggested 1,100 calories which is the approximate equivalent of 14 units of beer or wine.\n";
        } else if ([self.typeCell.valueLabel.text isEqualToString:@"Alcohol free days"]) {
            return @"We’ve suggested 3 alcohol free days as the drinking guidelines recommend 2 to 4. Read the drinking guidelines in full here.\n";
        } else if ([self.typeCell.valueLabel.text isEqualToString:@"Spending"]) {
            return @"You can choose to add the price when recording your drinks.\n\n";
        } else {
            return @"";
        }
    }
    
    return [super tableView:tableView titleForFooterInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case PXDetailsSection:
            return 40.0;
        case PXToggleSection:
            return 48.0 - PXSpacingHeight;
        case 2:
            return PXSpacingHeight;
        default:
            return [super tableView:tableView heightForHeaderInSection:section];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(nonnull UITableViewHeaderFooterView *)view forSection:(NSInteger)section {
    
    // Clear out any GR's in case cells are reused somehow (shouldnt be for this table but jic)
    for (UIGestureRecognizer *gestureRecognizer in view.gestureRecognizers) {
        [view removeGestureRecognizer:gestureRecognizer];
    }
    
    if (section != PXDetailsSection) {
        return;
    }
    
    // Convert to attributed text. Make it a little bigger methinks...
    NSMutableAttributedString *attribText = [[NSMutableAttributedString alloc] initWithString:view.textLabel.text];
    CGFloat fontSize = view.textLabel.font.pointSize + 1;
    NSRange fullRange = NSMakeRange(0, attribText.length);
    NSDictionary *attribs = @{NSFontAttributeName: [UIFont systemFontOfSize:fontSize]};
    [attribText addAttributes:attribs range:fullRange];
    
    // Make the "here" look like a link
    NSDictionary *linkAttributes = @{NSForegroundColorAttributeName: [UIColor drinkLessGreenColor],
                                     NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                                     NSFontAttributeName: [UIFont boldSystemFontOfSize:fontSize]
                                     };
    NSRange range = [view.textLabel.text rangeOfString:@"here" options:NSCaseInsensitiveSearch];
    
    
    // Not all of them will have the same text
    if (range.location != NSNotFound) {
        [attribText addAttributes:linkAttributes range:range];
        
        // Link it up....
        if (view.gestureRecognizers.count == 0) {
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pressedGuidelinesLink)];
            [view addGestureRecognizer:tapGesture];
        }
    }
    view.textLabel.attributedText = attribText;
}

- (void)pressedGuidelinesLink {
    PXWebViewController *webViewController = [[PXWebViewController alloc] initWithResource:@"drinking-guidelines"];
    webViewController.view.backgroundColor = [UIColor whiteColor];
    webViewController.title = @"Drinking guidelines";
//    [self.navigationController presentViewController:webViewController animated:YES completion:nil];
    [self.navigationController pushViewController:webViewController animated:YES];
}
//
//- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
//    if (section != PXDetailsSection) {
//        return [super tableView:tableView viewForFooterInSection:section];
//    }
//
//    // Make the footer linkable
//    NSString *text = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
//    NSRange range = [text rangeOfString:@"units" options:NSCaseInsensitiveSearch];
//    if (range.location != NSNotFound) {
//        CGFloat fontSize = view.textLabel.font.pointSize;
//        NSDictionary *linkAttributes = @{NSForegroundColorAttributeName: [UIColor drinkLessGreenColor],
//                                         NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
//                                         NSFontAttributeName: [UIFont boldSystemFontOfSize:fontSize]
//                                         };
//        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:view.textLabel.text];
//        [attributedText addAttributes:linkAttributes range:range];
//
//        view.textLabel.attributedText = attributedText;
//
//        if (view.gestureRecognizers.count == 0) {
//            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pressedInfoButton:)];
//            [view addGestureRecognizer:tapGesture];
//        }
//}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    
    if (section == PXToggleSection && self.shouldStartAsNewGoal) {
        return [super tableView:tableView heightForFooterInSection:section];
    } else if (section == PXDetailsSection) {
        return 90;
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
    } else if (cell == self.targetMaxCell) {
        PXGoalType goalType = self.goal.goalType.integerValue;
        BOOL hasTextField = (goalType == PXGoalTypeCalories ||
                             goalType == PXGoalTypeSpending);
        if (hasTextField) {
            [self.targetMaxCell.textField becomeFirstResponder];
        }
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - Actions

- (void)skipPressed {
    NSParameterAssert(self.isOnboarding);
    [self _onboardingFinishedSetGoal];
}

// Segue to the final screen
- (void)_onboardingFinishedSetGoal {
    NSParameterAssert(self.isOnboarding);
    
    // This triggers the end and the dismissal of the onboarding moal
    PXIntroManager.sharedManager.stage = PXIntroStageFinished;
    [PXIntroManager.sharedManager save];
}

- (IBAction)showInfo:(id)sender {
    [PXInfoViewController showResource:@"goal-edit" fromViewController:self];
}

- (IBAction)toggledSwitch:(UISwitch *)sender {
    if (sender == self.toggleCell.toggleSwitch && !self.isNewGoal) {
        self.startAsNewGoal = sender.isOn;
    }
}

// refers to the top right button only.
- (IBAction)pressedSave:(id)sender {
    [self _saveGoalData];
    
    if (self.isOnboarding) {
        [self _onboardingFinishedSetGoal];
    } else if (self.navigationController.childViewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
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
        self.targetMaxCell.textField.textColor = UIColor.drinkLessGreenColor;
        self.targetMaxCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-edit"]];
    } else {
        self.targetMaxCell.quantityControl.value = self.goal.targetMax.integerValue;
        self.targetMaxCell.accessoryView = nil;
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
    CGFloat maxHeight = self.tableView.rowHeight * 4;
    if (height > maxHeight) {
        height = maxHeight;
    }
    [self showPopoverWithViewController:itemListVC fromView:cell size:CGSizeMake(240.0, height)];
}

- (void)showPopoverWithViewController:(UIViewController *)viewController fromView:(UIView *)view size:(CGSize)size {
    
    PXRecordCell *recCell = (PXRecordCell *)view;
    CGSize s = recCell.valueLabel.frame.size;
    CGPoint pt = recCell.valueLabel.frame.origin;
    pt.x = 0;
    CGRect r = CGRectMake(pt.x, pt.y, s.width, s.height);
    
    self.popoverVC = [[PopoverVC alloc] initWithContentVC:viewController preferredSize:size sourceView:recCell.valueLabel sourceRect:r];
    
    [self presentViewController:self.popoverVC animated:YES completion:nil];
}

- (void)showUnitGiude {
    
    if (self.goal.goalType.integerValue != PXGoalTypeUnits &&
        self.goal.goalType.integerValue != PXGoalTypeCalories) {
        
        self.guideLabl.text = @"";
        return;
    }
    
    self.guideLabl.text = [NSMutableString stringWithFormat:@"Click here for a guide to the number of units and calories in common drinks."];
    
    NSRange range = [self.guideLabl.text rangeOfString:@"Click here" options:NSCaseInsensitiveSearch];
    if (range.location != NSNotFound) {
        NSDictionary *linkAttributes = @{NSForegroundColorAttributeName: [UIColor drinkLessGreenColor],
                                         NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:self.guideLabl.text];
        [attributedText addAttributes:linkAttributes range:range];
        self.guideLabl.attributedText = attributedText;
    }
}

//////////////////////////////////////////////////////////
// MARK: - PXItemListVCDelegate
//////////////////////////////////////////////////////////

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
        [self.tableView reloadData];
    }
    [self.popoverVC dismissViewControllerAnimated:YES completion:nil];
    
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

//---------------------------------------------------------------------

- (void)_saveGoalData {
    [self updateGoal];
    
    if (self.shouldStartAsNewGoal) {
        // Ending reference goal and making new copy a different record on parse
        self.referenceGoal.endDate = self.goal.startDate;
        
        [self.referenceGoal saveToServer];
        self.goal.parseObjectId = nil;
        self.goal.parseUpdated = @NO;
    }
    else if (!self.isNewGoal) {
        // Replacing reference goal with an updated copy
        [self.context deleteObject:self.referenceGoal];
    }
    [self.context save:nil];
    [self.goal saveToServer];
}


@end
