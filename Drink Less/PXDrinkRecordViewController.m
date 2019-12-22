//
//  PXDrinkRecordViewController.m
//  drinkless
//
//  Created by Edward Warrender on 06/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXDrinkRecordViewController.h"
#import "PXDrinkRecord+Extras.h"
#import "PXDrink.h"
#import "PXDrinkServing.h"
#import "PXDrinkType.h"
#import "PXDrinkAddition.h"
#import "PXRecordCell.h"
#import "FPPopoverKeyboardResponsiveController.h"
#import "PXItemListVC.h"
#import "PXDateStepControl.h"
#import "PXAlcoholFreeRecord+Extras.h"
#import "PXUnitsGuideViewController.h"
#import "PXDrinkCalculator.h"
#import "PXInfoViewController.h"
#import "PXDebug.h"
#import "PXSolidButton.h"
#import "drinkless-Swift.h"

static CGFloat PXSpacingHeight = 12.0;

@interface PXDrinkRecordViewController () <PXItemListVCDelegate, PXNumberFieldChangeDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet PXDateStepControl *dateStepControl;
@property (weak, nonatomic) IBOutlet PXRecordCell *typeCell;
@property (weak, nonatomic) IBOutlet PXRecordCell *additionCell;
@property (weak, nonatomic) IBOutlet PXRecordCell *abvCell;
@property (weak, nonatomic) IBOutlet PXRecordCell *sizeCell;
@property (weak, nonatomic) IBOutlet PXRecordCell *priceCell;
@property (weak, nonatomic) IBOutlet PXRecordCell *quantityCell;
@property (weak, nonatomic) IBOutlet PXRecordCell *favouriteCell;
@property (weak, nonatomic) IBOutlet PXSolidButton *deleteBtn;
@property (strong, nonatomic) FPPopoverController *popoverVC;
@property (strong, nonatomic) UITableViewHeaderFooterView *unitsFooterView;
@property (strong, nonatomic) NSArray *servings;
@property (strong, nonatomic) NSArray *types;
@property (strong, nonatomic) NSArray *additions;
@property (strong, nonatomic) NSNumber *defaultABV;
@property (strong, nonatomic) NSNumber *defaultPrice;
@property (strong, nonatomic) NSMutableSet *hiddenCells;
@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) BOOL isEdit;

@end

@implementation PXDrinkRecordViewController

+ (PXDrinkRecordViewController *)recordViewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"DrinksTracker" bundle:nil];
    PXDrinkRecordViewController *recordViewController = [storyboard instantiateViewControllerWithIdentifier:@"PXDrinkRecordViewController"];
    return recordViewController;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.isEdit = [self.parentViewController isMemberOfClass:[TabBarCalendarNavVC class]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [DataServer.shared trackScreenView:@"Drink record"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Save button uses default window tint. Also hide if this is not an edit
    self.deleteBtn.tintColor = [UIColor drinkLessRedColor];
    self.deleteBtn.hidden = self.drinkRecord.hasChanges;  // An edit shouldnt have changes yet
    
    
    
//    self.servings = [self.drinkRecord.drink.servings sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"millilitres" ascending:YES]]];
//
    // For servings include only the last 3 custom including the one selected if any
    NSMutableArray <PXDrinkServing *> *showServings = [self.drinkRecord.drink.servings sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO]]].mutableCopy;
    // three total
    NSInteger customsRemaining = self.drinkRecord.serving.isCustom ? 2 : 3;
    for (PXDrinkServing *serving in showServings.copy) {
        // Remove from the list if it's not the selected or we've run out
        if (serving.isCustom) {
            if ([serving.identifier isEqualToNumber:self.drinkRecord.serving.identifier]) {
                continue;
            }
            if (customsRemaining-- > 0) {
                continue;
            }
            // Remove it
            [showServings removeObject:serving];
        }
    }
    self.servings = [showServings sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]]];

    self.types = [self.drinkRecord.drink.types sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]]];
    
    self.additions = [self.drinkRecord.drink.additions sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]]];
    
    self.tableView.rowHeight = 44.0; // Required on iOS 8
    self.title = self.drinkRecord.drink.name;
    
    // Accessory images
    UIImage *dropdownIcon = [UIImage imageNamed:@"icon-dropdown"];
    UIImage *editableIcon = [UIImage imageNamed:@"icon-edit"];
    UIColor *editableColor = [UIColor drinkLessGreenColor];
    
    self.abvCell.numberFieldDelegate.delegate = self;
    self.abvCell.formatType = PXFormatTypePercentage;
    self.abvCell.textField.text = [self.abvCell.numberFieldDelegate.numberFormatter stringFromNumber:self.drinkRecord.abv];
    self.abvCell.accessoryView = [[UIImageView alloc] initWithImage:editableIcon];
    self.abvCell.valueLabel.textColor = editableColor;
    self.abvCell.textField.textColor = editableColor;
    
    self.sizeCell.numberFieldDelegate.delegate = self;
    self.sizeCell.formatType = PXFormatTypeVolume;
    self.sizeCell.valueLabel.hidden = self.drinkRecord.serving.isCustom;
    self.sizeCell.textField.hidden = !self.drinkRecord.serving.isCustom;
    self.sizeCell.valueLabel.text = self.drinkRecord.serving.name;
    self.sizeCell.textField.text = [self.sizeCell.numberFieldDelegate.numberFormatter stringFromNumber:self.drinkRecord.serving.millilitres];
    self.sizeCell.valueLabel.text = self.drinkRecord.serving.name;
//    self.sizeCell.textField.enabled = NO;
    self.sizeCell.textField.userInteractionEnabled = NO;
    self.sizeCell.accessoryView = [[UIImageView alloc] initWithImage:dropdownIcon];
//    self.sizeCell.valueLabel.textColor = editableColor;
    
    self.priceCell.formatType = PXFormatTypeCurrency;
    self.priceCell.accessoryView = [[UIImageView alloc] initWithImage:editableIcon];
    self.priceCell.textField.textColor = editableColor;
    
    self.dateStepControl.date = self.drinkRecord.date;
    
    self.quantityCell.quantityControl.value = self.drinkRecord.quantity.integerValue;
    
    self.priceCell.textField.text = [self.priceCell.numberFieldDelegate.numberFormatter stringFromNumber:self.drinkRecord.price];
    
    self.additionCell.accessoryView = [[UIImageView alloc] initWithImage:dropdownIcon];
//    self.additionCell.valueLabel.textColor = editableColor;
    
    if (self.isFavouritesHidden) {
        [self hideCell:self.favouriteCell];
    }
    self.favouriteCell.toggleSwitch.on = self.drinkRecord.favourite.boolValue;
    
    if (!self.drinkRecord.type) {
        [self hideCell:self.typeCell];
    } else {
        self.typeCell.accessoryView = [[UIImageView alloc] initWithImage:dropdownIcon];
        self.typeCell.titleLabel.text = self.drinkRecord.drink.name;
        self.typeCell.valueLabel.text = self.drinkRecord.type.name;
//        self.typeCell.valueLabel.textColor = editableColor;

    }
    
    if (!self.drinkRecord.addition) {
        [self hideCell:self.additionCell];
    } else {
        self.additionCell.valueLabel.text = self.drinkRecord.addition.name;
    }
    
    [self updateDefaultABV];
    [self updateDefaultPrice];
}

- (void)hideCell:(UITableViewCell *)cell {
    cell.hidden = YES;
    if (!self.hiddenCells) {
        self.hiddenCells = [NSMutableSet setWithObject:cell];
    } else {
        [self.hiddenCells addObject:cell];
    }
}

- (PXDrinkRecord *)fetchDrinkRecordWithMatchingKeys:(NSArray *)keys {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PXDrinkRecord"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
    fetchRequest.fetchLimit = 1;
    
    NSPredicate *excludeSelf = [NSPredicate predicateWithFormat:@"SELF != %@", self.drinkRecord];
    NSPredicate *excludePlaceholders = [NSPredicate predicateWithFormat:@"date != nil"];
    NSMutableArray *subpredicates = @[excludeSelf, excludePlaceholders].mutableCopy;
    for (NSString *key in keys) {
        id value = [self.drinkRecord valueForKey:key];
        if (value) {
            [subpredicates addObject:[NSPredicate predicateWithFormat:@"%K == %@", key, value]];
        }
    }
    fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subpredicates];
    
    NSArray *results = [self.context executeFetchRequest:fetchRequest error:NULL];
    return results.firstObject;
}

- (NSNumber *)calculateABVMatch {
    PXDrinkRecord *matchingDrinkRecord = [self fetchDrinkRecordWithMatchingKeys:@[@"drink", @"typeID", @"additionID"]];
    if (matchingDrinkRecord) {
        return matchingDrinkRecord.abv;
    }
    return @(PXDefaultAbv(self.drinkRecord.drink.identifier.integerValue));
}

- (NSNumber *)calculatePriceMatch {
    PXDrinkRecord *matchingDrinkRecord = [self fetchDrinkRecordWithMatchingKeys:@[@"drink", @"typeID", @"servingID", @"additionID", @"abv"]];
    if (matchingDrinkRecord) {
        return matchingDrinkRecord.price;
    }
    return @0;
}

- (void)updateDefaultABV {
    if (self.isAddingDrinkRecord) {
        self.defaultABV = [self calculateABVMatch];
        [self updateAlcoholUnits];
    }
}

- (void)updateDefaultPrice {
    if (self.isAddingDrinkRecord) {
        self.defaultPrice = [self calculatePriceMatch];
    }
}

#pragma mark - Properties

- (void)setDefaultABV:(NSNumber *)defaultABV {
    if (![_defaultABV isEqualToNumber:defaultABV]) {
        _defaultABV = defaultABV;
        self.drinkRecord.abv = defaultABV;
        self.abvCell.textField.text = [self.abvCell.numberFieldDelegate.numberFormatter stringFromNumber:self.drinkRecord.abv];
    }
}

- (void)setDefaultPrice:(NSNumber *)defaultPrice {
    if (![_defaultPrice isEqualToNumber:defaultPrice]) {
        _defaultPrice = defaultPrice;
        self.drinkRecord.price = defaultPrice;
        self.priceCell.textField.text = [self.priceCell.numberFieldDelegate.numberFormatter stringFromNumber:self.drinkRecord.price];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if (section == 1) {
        self.unitsFooterView = (UITableViewHeaderFooterView *)view;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateAlcoholUnits];
        });
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if ([self.hiddenCells containsObject:cell]) {
        return 0;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return PXSpacingHeight * 2.0;
        case 1:
            return 40.0 - PXSpacingHeight;
        case 2:
            return PXSpacingHeight;
        default:
            return [super tableView:tableView heightForHeaderInSection:section];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    NSString *footer = [tableView.dataSource tableView:tableView titleForFooterInSection:section];
    if (footer.length != 0) {
        return 40.0 - PXSpacingHeight;
    }
    return PXSpacingHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView endEditing:YES];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell == self.typeCell) {
        [self showList:self.types
                object:self.drinkRecord.type
         fromIndexPath:indexPath];
    }
    else if (cell == self.additionCell) {
        [self showList:self.additions
                object:self.drinkRecord.addition
         fromIndexPath:indexPath];
    }
    else if (cell == self.sizeCell) {
        [self showList:self.servings
                object:self.drinkRecord.serving
         fromIndexPath:indexPath];
    } else if (cell == self.abvCell) {
        [self.abvCell.textField becomeFirstResponder];
    } else if (cell == self.priceCell) {
        [self.priceCell.textField becomeFirstResponder];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - Actions

- (IBAction)showInfo:(id)sender {
    [PXInfoViewController showResource:@"drink-edit" fromViewController:self];
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

- (void)updateAlcoholUnits {
    static NSNumberFormatter *numberFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        numberFormatter = [[NSNumberFormatter alloc] init];
        numberFormatter.maximumFractionDigits = 1;
    });
    UILabel *footerLabel = self.unitsFooterView.textLabel;
    footerLabel.textAlignment = NSTextAlignmentRight;
    footerLabel.textColor = [UIColor drinkLessGreenColor];
    footerLabel.font = [UIFont systemFontOfSize:17.0];
    
    NSString *noun = (self.drinkRecord.totalUnits.floatValue == 1.0) ? @"unit" : @"units";
    footerLabel.text = [NSString stringWithFormat:@"%@ %@ total", [numberFormatter stringFromNumber:self.drinkRecord.totalUnits], noun];
    
    CGFloat inset = 30.0;
    CGRect rect = footerLabel.frame;
    rect.origin.x = inset;
    rect.origin.y = PXSpacingHeight;
    rect.size.width = self.tableView.bounds.size.width - (inset * 2.0);
    footerLabel.frame = rect;
}

- (IBAction)changedQuantity:(PXQuantityControl *)sender {
    self.drinkRecord.quantity = @(sender.value);
    [self updateAlcoholUnits];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    [self.view endEditing:YES];
    
    if ([identifier isEqualToString:@"save"] || [identifier isEqualToString:@"saveTopBar"]) {
        [self _doSave];
    }
    if (self.isEdit) {
        [self.navigationController popViewControllerAnimated:YES];
        return NO;
    }
    return YES;
}
- (IBAction)savePressedTopBar:(id)sender {
}


//- (IBAction)unwindToTabBarCalendarNavVC:(UIStoryboardSegue *)unwindSegue {
//    UIViewController *sourceViewController = unwindSegue.sourceViewController;
//    // Use data from the view controller which initiated the unwind segue
//}

//-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
//    NSLog(@"******* sds *******");
//}

- (IBAction)pressedSave {
//    if (self.isEdit) {
//        [self _doSave];
//        // Unwind the segue
//        [self.navigationController popViewControllerAnimated:YES];
//    }
//    [self performSegueWithIdentifier:@"save" sender:nil];
}

#pragma mark - PXItemListVCDelegate

- (void)itemListVC:(PXItemListVC *)itemListVC chosenIndex:(NSInteger)chosenIndex {
    NSManagedObject *object = itemListVC.itemsArray[chosenIndex];
    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell == self.typeCell) {
        self.drinkRecord.typeID = [object valueForKey:@"identifier"];
        [self.context refreshObject:self.drinkRecord mergeChanges:YES];
        self.typeCell.valueLabel.text = self.drinkRecord.type.name;
        [self updateDefaultABV];
        [self updateDefaultPrice];
    }
    else if (cell == self.additionCell) {
        self.drinkRecord.additionID = [object valueForKey:@"identifier"];
        [self.context refreshObject:self.drinkRecord mergeChanges:YES];
        self.additionCell.valueLabel.text = self.drinkRecord.addition.name;
        [self updateDefaultABV];
        [self updateDefaultPrice];
    }
    else if (cell == self.sizeCell) {
        
        NSNumber *identifier = [object valueForKey:@"identifier"];
        
        // If custom placeholder id, then defer until they enter in a value
        if (identifier.integerValue != kPXDrinkServingCustomIdentifier) {
            self.drinkRecord.servingID = [object valueForKey:@"identifier"];
            [self.context refreshObject:self.drinkRecord mergeChanges:YES];
            self.sizeCell.valueLabel.text = self.drinkRecord.serving.name;
            self.sizeCell.textField.hidden = YES;
            self.sizeCell.valueLabel.hidden = NO;
            [self updateAlcoholUnits];
            [self updateDefaultPrice];
        } else {
            // Make the cell editable
            self.sizeCell.textField.hidden = NO;
            self.sizeCell.valueLabel.hidden = YES;
            self.sizeCell.textField.userInteractionEnabled = YES;
            [self.sizeCell.textField becomeFirstResponder];
        }
    }
    [self.popoverVC dismissPopoverAnimated:YES];
}

#pragma mark - PXNumberFieldChangeDelegate

- (void)finishedEditingTextField:(UITextField *)textField {
    if (textField == self.abvCell.textField) {
        self.drinkRecord.abv = [self.abvCell.numberFieldDelegate.numberFormatter numberFromString:self.abvCell.textField.text];
        [self updateAlcoholUnits];
        [self updateDefaultPrice];
    }
    else if (textField == self.sizeCell.textField) {
        textField.userInteractionEnabled = NO;
        
        // assign fetched/new custom serving for the specified size
        // @TODO: NEXT
        NSNumber *volume = [self.sizeCell.numberFieldDelegate.numberFormatter numberFromString:self.sizeCell.textField.text];
        PXDrinkServing *serving = [PXDrinkServing drinkServingForCustomVolume:volume forDrink:self.drinkRecord.drink context:self.context];
        self.drinkRecord.servingID = serving.identifier;
        //[self.context save:nil];
        [self.context refreshObject:self.drinkRecord mergeChanges:YES];
        [self updateAlcoholUnits];
        [self updateDefaultPrice];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [self.view endEditing:YES];
    
//    if ([segue.identifier isEqualToString:@"save"] || [segue.identifier isEqualToString:@"saveTopBar"]) {
//        [self _doSave];
//    }
}

//////////////////////////////////////////////////////////
// MARK: - Actions
//////////////////////////////////////////////////////////

- (IBAction)deletePressed:(id)sender {
    NSParameterAssert(self.isEdit);
    NSString *title = @"Delete this drink entry?";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != 1) return;
    
    // Delete the drink record
    logd(@"Deleting Drink Record...");
    [self.context deleteObject:self.drinkRecord];
    NSError *err;
    [self.context save:&err];
    if (err) {
        [AlertManager.shared showErrorAlert:err];
    }
    
    // Unwind the segue
    [self.navigationController popViewControllerAnimated:YES];
}



- (void)_doSave {
    self.drinkRecord.price = [self.priceCell.numberFieldDelegate.numberFormatter numberFromString:self.priceCell.textField.text];
    self.drinkRecord.favourite = @(self.favouriteCell.toggleSwitch.isOn);
    self.drinkRecord.date = self.dateStepControl.date;
    self.drinkRecord.timezone = NSCalendar.currentCalendar.timeZone.name; // important to use this to grab our swizzle
    [self.context save:nil];
    [self.context refreshObject:self.drinkRecord mergeChanges:NO];
    [self.drinkRecord saveToServer];
    
    [PXAlcoholFreeRecord setFreeDay:NO date:self.drinkRecord.date context:self.context];
}

@end

