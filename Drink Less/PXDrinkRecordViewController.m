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

static CGFloat PXSpacingHeight = 12.0;

@interface PXDrinkRecordViewController () <PXItemListVCDelegate, PXNumberFieldChangeDelegate>

@property (weak, nonatomic) IBOutlet PXDateStepControl *dateStepControl;
@property (weak, nonatomic) IBOutlet PXRecordCell *typeCell;
@property (weak, nonatomic) IBOutlet PXRecordCell *additionCell;
@property (weak, nonatomic) IBOutlet PXRecordCell *abvCell;
@property (weak, nonatomic) IBOutlet PXRecordCell *sizeCell;
@property (weak, nonatomic) IBOutlet PXRecordCell *priceCell;
@property (weak, nonatomic) IBOutlet PXRecordCell *quantityCell;
@property (weak, nonatomic) IBOutlet PXRecordCell *favouriteCell;
@property (strong, nonatomic) FPPopoverController *popoverVC;
@property (strong, nonatomic) UITableViewHeaderFooterView *unitsFooterView;
@property (strong, nonatomic) NSArray *servings;
@property (strong, nonatomic) NSArray *types;
@property (strong, nonatomic) NSArray *additions;
@property (strong, nonatomic) NSNumber *defaultABV;
@property (strong, nonatomic) NSNumber *defaultPrice;
@property (strong, nonatomic) NSMutableSet *hiddenCells;
@property (nonatomic) CGFloat keyboardHeight;

@end

@implementation PXDrinkRecordViewController

+ (PXDrinkRecordViewController *)recordViewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"DrinksTracker" bundle:nil];
    PXDrinkRecordViewController *recordViewController = [storyboard instantiateViewControllerWithIdentifier:@"PXDrinkRecordViewController"];
    return recordViewController;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [PXTrackedViewController trackScreenName:@"Drink record"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.servings = [self.drinkRecord.drink.servings sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"millilitres" ascending:YES]]];
    
    self.types = [self.drinkRecord.drink.types sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]]];
    
    self.additions = [self.drinkRecord.drink.additions sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]]];
    
    self.tableView.rowHeight = 44.0; // Required on iOS 8
    self.title = self.drinkRecord.drink.name;
    
    self.abvCell.numberFieldDelegate.delegate = self;
    self.abvCell.formatType = PXFormatTypePercentage;
    self.abvCell.textField.text = [self.abvCell.numberFieldDelegate.numberFormatter stringFromNumber:self.drinkRecord.abv];
    
    self.priceCell.formatType = PXFormatTypeCurrency;
    self.dateStepControl.date = self.drinkRecord.date;
    self.sizeCell.valueLabel.text = self.drinkRecord.serving.name;
    self.quantityCell.quantityControl.value = self.drinkRecord.quantity.integerValue;
    
    self.priceCell.textField.text = [self.priceCell.numberFieldDelegate.numberFormatter stringFromNumber:self.drinkRecord.price];
    
    if (self.isFavouritesHidden) {
        [self hideCell:self.favouriteCell];
    }
    self.favouriteCell.toggleSwitch.on = self.drinkRecord.favourite.boolValue;
    
    if (!self.drinkRecord.type) {
        [self hideCell:self.typeCell];
    } else {
        self.typeCell.titleLabel.text = self.drinkRecord.drink.name;
        self.typeCell.valueLabel.text = self.drinkRecord.type.name;
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

- (IBAction)pressedSave:(id)sender {
    [self performSegueWithIdentifier:@"save" sender:nil];
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
        self.drinkRecord.servingID = [object valueForKey:@"identifier"];
        [self.context refreshObject:self.drinkRecord mergeChanges:YES];
        self.sizeCell.valueLabel.text = self.drinkRecord.serving.name;
        [self updateAlcoholUnits];
        [self updateDefaultPrice];
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
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [self.view endEditing:YES];
    
    if ([segue.identifier isEqualToString:@"save"]) {
        self.drinkRecord.price = [self.priceCell.numberFieldDelegate.numberFormatter numberFromString:self.priceCell.textField.text];
        self.drinkRecord.favourite = @(self.favouriteCell.toggleSwitch.isOn);
        self.drinkRecord.date = self.dateStepControl.date;
        self.drinkRecord.timezone = NSTimeZone.localTimeZone.name;
        [self.context save:nil];
        [self.drinkRecord saveToParse];
        
        [PXAlcoholFreeRecord setFreeDay:NO date:self.drinkRecord.date context:self.context];
    }
}

@end
