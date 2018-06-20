//
//  PXWeekSummaryViewController.m
//  drinkless
//
//  Created by Edward Warrender on 21/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXWeekSummaryViewController.h"
#import "PXBlurAnimationController.h"
#import "PXWeekTitleView.h"
#import "PXWeekAlcoholFreeView.h"
#import "PXPlaceholderViewRenamed.h"
#import "PXWeekDrinkCell.h"
#import "PXWeekFiguresView.h"
#import "PXDrinkRecord+Extras.h"
#import "PXDrink.h"
#import "PXDrinkType.h"
#import "PXDrinkServing.h"
#import "PXCoreDataManager.h"

@interface PXWeekSummaryViewController () <UIViewControllerTransitioningDelegate, PXBlurAnimationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIView *panelView;
@property (weak, nonatomic) IBOutlet PXWeekTitleView *titleView;
@property (weak, nonatomic) IBOutlet PXWeekAlcoholFreeView *alcoholFreeView;
@property (weak, nonatomic) IBOutlet PXPlaceholderViewRenamed *placeholderView;
@property (weak, nonatomic) IBOutlet UIView *consumptionView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet PXWeekFiguresView *figuresView;

@end

@implementation PXWeekSummaryViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.modalPresentationStyle = UIModalPresentationCustom;
    self.transitioningDelegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.panelView.layer.cornerRadius = 4.0;
    self.titleView.date = self.weekSummary.lastDate;
    self.alcoholFreeView.numberOfFreeDays = self.weekSummary.alcoholFreeDays;
    self.figuresView.weekSummary = self.weekSummary;
    
    BOOL noObjects = self.weekSummary.drinkRecords.count == 0;
    self.consumptionView.hidden = noObjects;
    self.placeholderView.hidden = !noObjects;
    
    self.drinkRecords = [NSMutableArray array];
    
    for (PXDrinkRecord *record in self.weekSummary.drinkRecords) {
        
//        NSLog(@"typeID = %@\n drink Group = %@\n name = %@ ", record.typeID, record.groupName, record.drink.name);
        BOOL exist = NO;
        for (PXDrinkRecord *existDrinkRecord in self.drinkRecords) {
            
            if (record.typeID.integerValue == existDrinkRecord.typeID.integerValue &&
                [record.drink.name isEqualToString:existDrinkRecord.drink.name]) {
                
                NSInteger quantity = existDrinkRecord.quantity.integerValue + record.quantity.integerValue;
                existDrinkRecord.quantity = @(quantity);
                exist = YES;
            }
        }
        
        if (!exist) {

            PXDrinkRecord *newDrinkRecord = [record copyDrinkRecordIntoContext:record.managedObjectContext];
            newDrinkRecord.iconName = record.iconName;
            newDrinkRecord.quantity = record.quantity;
            newDrinkRecord.serving.name = record.serving.name;
            newDrinkRecord.type.name = record.type.name;
            [self.drinkRecords addObject:newDrinkRecord];
        }
    }
    
    if (noObjects) {
        self.placeholderView.subtitleLabel.font = [UIFont systemFontOfSize:14.0];
        [self.placeholderView setImage:[UIImage imageNamed:@"goal-hit"] title:nil subtitle:@"Keep up the good work!" footer:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.panelView.alpha = 0.0;
    self.panelView.transform = CGAffineTransformMakeScale(0.2, 0.2);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.0 options:0 animations:^{
            self.panelView.alpha = 1.0;
            self.panelView.transform = CGAffineTransformIdentity;
        } completion:nil];
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.panelView.alpha = 0.0;
        self.panelView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    }];
    
//    delete temp entities from db
    for (PXDrinkRecord *existDrinkRecord in self.drinkRecords) {
        
        [existDrinkRecord.managedObjectContext deleteObject:existDrinkRecord];
    }
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return [PXBlurAnimationController animationControllerPresenting:YES delegate:self];
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return [PXBlurAnimationController animationControllerPresenting:NO delegate:self];
}

#pragma mark - PXBlurAnimationControllerDelegate

- (void)animationControllerDidCaptureScreenshot:(UIImage *)screenshot {
    self.backgroundImageView.image = screenshot;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.drinkRecords.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PXDrinkRecord *drinkRecord = self.drinkRecords[indexPath.item];
    PXWeekDrinkCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"drinkCell" forIndexPath:indexPath];
    cell.iconImageView.image = [UIImage imageNamed:drinkRecord.iconName];
    cell.quantityLabel.text = [NSString stringWithFormat:@"x%li", (long)drinkRecord.quantity.integerValue];
    cell.titleLabel.text = drinkRecord.type.name ?: drinkRecord.drink.name;
    cell.sizeLabel.text = drinkRecord.serving.name;
    return cell;
}

@end
