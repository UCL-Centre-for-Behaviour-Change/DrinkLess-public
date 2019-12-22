//
//  PXUnitsGuideViewController.m
//  drinkless
//
//  Created by Edward Warrender on 16/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXUnitsGuideViewController.h"
#import "PXUnitGuideCell.h"
#import "PXHorizontalPagingLayout.h"
#import "PXCoreDataManager.h"
#import "PXDrink.h"
#import "PXDrinkRecord+Extras.h"
#import "PXDrinkType.h"
#import "PXDrinkServing.h"

@interface PXUnitsGuideViewController ()

@property (weak, nonatomic) IBOutlet PXHorizontalPagingLayout *layout;
@property (strong, nonatomic) NSArray *unitsGuideDrinks;
@property (strong, nonatomic) NSNumberFormatter *numberFormatter;

@end

@implementation PXUnitsGuideViewController

+ (UINavigationController *)navigationController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"UnitsGuide" bundle:nil];
    return [storyboard instantiateInitialViewController];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.numberFormatter = [[NSNumberFormatter alloc] init];
    self.numberFormatter.maximumFractionDigits = 1;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

#pragma mark - Properties

- (NSArray *)unitsGuideDrinks {
    if (!_unitsGuideDrinks) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PXDrinkRecord"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"date == nil && groupName == 'unitsGuide'"];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"drink.index" ascending:YES]];
        NSManagedObjectContext *context = [PXCoreDataManager sharedManager].managedObjectContext;
        _unitsGuideDrinks = [context executeFetchRequest:fetchRequest error:nil];
    }
    return _unitsGuideDrinks;
}

#pragma mark - Actions

- (IBAction)pressedDone:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.unitsGuideDrinks.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PXUnitGuideCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"unitGuideCell" forIndexPath:indexPath];
    PXDrinkRecord *drinkRecord = self.unitsGuideDrinks[indexPath.row];
    cell.imageView.image = [UIImage imageNamed:drinkRecord.iconName];
    cell.nameLabel.text = drinkRecord.drink.name;
    cell.sizeLabel.text = drinkRecord.serving.name;
    cell.caloriesLabel.text = [NSString stringWithFormat:@"Calories %.0f", drinkRecord.totalCalories.floatValue];
    cell.abvLabel.text = [NSString stringWithFormat:@"ABV %.01f%%", drinkRecord.abv.floatValue];
    cell.unitsValueLabel.text = [self.numberFormatter stringFromNumber:drinkRecord.totalUnits];
    cell.unitsTitleLabel.text = (drinkRecord.totalUnits.floatValue == 1.0) ? @"unit" : @"units";
    return cell;
}

@end
