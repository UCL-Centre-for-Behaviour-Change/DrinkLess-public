//
//  PXTrackerDrinksViewController.m
//  drinkless
//
//  Created by Edward Warrender on 26/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXTrackerDrinksViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "PXCoreDataManager.h"
#import "PXDrink.h"
#import "PXDrinkRecord+Extras.h"
#import "NSManagedObject+PXFindByID.h"
#import "PXDrinkOptionCell.h"
#import "PXDrinkType.h"
#import "PXDrinkServing.h"
#import "PXHorizontalPagingLayout.h"
#import "PXPlaceholderViewRenamed.h"
#import "PXTrackerAlcoholFreeView.h"
#import "PXDrinkRecordViewController.h"
#import "PXDrinkRecord+Extras.h"
#import "TSMessageView.h"
#import "PXAlcoholFreeRecord+Extras.h"
#import "PXStepGuide.h"
#import "PXGroupsManager.h"

typedef NS_ENUM(NSInteger, PXPanelType) {
    PXStandardPanelType   = 1,
    PXFavouritesPanelType = 2,
    PXRecentPanelType     = 3
};

static NSInteger const PXRecentPageLimit = 10;

@interface PXTrackerDrinksViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, PXDrinkOptionCellDelegate, PXHorizontalPagingLayoutDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet PXHorizontalPagingLayout *layout;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet PXTrackerAlcoholFreeView *alcoholFreeView;
@property (weak, nonatomic) IBOutlet PXPlaceholderViewRenamed *placeholderView;
@property (weak, nonatomic) IBOutlet UIView *drinksView;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *tabButtons;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSMutableArray *changes;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (nonatomic, getter = isEditingAllowed) BOOL editingAllowed;
@property (nonatomic, getter = isEditing) BOOL editing;
@property (nonatomic, getter = isAlcoholFreeDay) BOOL alcoholFreeDay;
@property (nonatomic) PXPanelType panelType;

@end

@implementation PXTrackerDrinksViewController

@synthesize panelViewController = _panelViewController;
@synthesize referenceDate = _referenceDate;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateFormat = @"EEE d MMM";
    
    self.context = [PXCoreDataManager sharedManager].managedObjectContext;
    
    for (UIButton *button in self.tabButtons) {
        [button addTarget:self action:@selector(pressedTabButton:) forControlEvents:UIControlEventTouchDown];
    }
    [self pressedTabButton:self.tabButtons.firstObject];
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
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"addDrinkRecord"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        PXDrinkRecordViewController *drinkRecordVC = (PXDrinkRecordViewController *)navigationController.topViewController;
        drinkRecordVC.addingDrinkRecord = YES;
        drinkRecordVC.context = [PXCoreDataManager temporaryContext];
        
        NSIndexPath *indexPath = self.collectionView.indexPathsForSelectedItems.firstObject;
        PXDrinkRecord *referenceRecord = [self.fetchedResultsController objectAtIndexPath:indexPath];
        PXDrinkRecord *newRecord = [referenceRecord copyDrinkRecordIntoContext:drinkRecordVC.context];
        newRecord.date = self.referenceDate;
        drinkRecordVC.drinkRecord = newRecord;
        drinkRecordVC.hideFavourite = referenceRecord.favourite.boolValue;
    }
}

- (IBAction)unwindWithSegue:(UIStoryboardSegue *)segue {
    if ([segue.identifier isEqualToString:@"save"] &&
        [segue.sourceViewController isKindOfClass:[PXDrinkRecordViewController class]]) {
        PXDrinkRecord *record = ((PXDrinkRecordViewController *)segue.sourceViewController).drinkRecord;
        NSString *message = [NSString stringWithFormat:@"Your %@ been successfully recorded. Thank you for doing that.", record.quantity.integerValue > 1 ? @"drinks have" : @"drink has"];

        [TSMessage showNotificationInViewController:[TSMessage defaultViewController]
                                              title:message
                                           subtitle:nil
                                               type:TSMessageNotificationTypeSuccess
                                           duration:2.0];
        
        // Delay sound by 0.4 seconds to sync with TSMessage
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC * 400), dispatch_get_main_queue(), ^{
            self.audioPlayer.currentTime = 0;
            [self.audioPlayer play];
        });

        [PXStepGuide completeStepWithID:@"drinks"];
    }
}

#pragma mark - Properties

- (void)setAlcoholFreeDay:(BOOL)alcoholFreeDay {
    _alcoholFreeDay = alcoholFreeDay;
    
    self.placeholderView.hidden = !alcoholFreeDay;
    self.drinksView.hidden = alcoholFreeDay;
    self.alcoholFreeView.toggleSwitch.on = alcoholFreeDay;
    
    NSString *subtitle;
    UIImage *image;
    if (alcoholFreeDay) {
        subtitle = [NSString stringWithFormat:@"%@ was alcohol free.", [self.dateFormatter stringFromDate:self.referenceDate]];
        if ([PXGroupsManager sharedManager].highSM.boolValue) {
            
            subtitle = [NSString stringWithFormat:@"%@\nKeep up the good work!", subtitle];
        }
        image = [UIImage imageNamed:@"goal-hit"];
    }
    [self.placeholderView setImage:image title:nil subtitle:subtitle footer:nil];
}

- (void)setReferenceDate:(NSDate *)referenceDate {
    _referenceDate = referenceDate;
    
    self.dateLabel.text = [self.dateFormatter stringFromDate:referenceDate];
    self.alcoholFreeDay = [PXAlcoholFreeRecord fetchFreeRecordsForCalendarDate:referenceDate context:self.context].count;
}

- (void)setPanelType:(PXPanelType)panelType {
    _panelType = panelType;
    
    BOOL isStandard = panelType == PXStandardPanelType;
    self.alcoholFreeView.collapsed = !isStandard;
    self.layout.numberOfRows = isStandard ? 2 : 3;
    
    NSString *title;
    switch (panelType) {
        case PXStandardPanelType:
            title = @"Add a drink";
            break;
        case PXFavouritesPanelType:
            title = @"Your Regulars";
            break;
        case PXRecentPanelType:
            title = @"Recently Used";
            break;
    }
    self.titleLabel.text = title;
    
    self.editing = NO;
    self.editingAllowed = (panelType == PXFavouritesPanelType);
    self.fetchedResultsController = nil;
    [self.collectionView reloadData];
}

#pragma mark - Actions

- (IBAction)tappedDate:(id)sender {
    self.panelViewController.datePicking = YES;
}

- (IBAction)toggleAlcoholFree:(UISwitch *)sender {
    [UIView animateWithDuration:0.7 delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.0 options:0 animations:^{
        self.alcoholFreeDay = sender.isOn;
    } completion:nil];
    
    if (self.isAlcoholFreeDay) {
        self.audioPlayer.currentTime = 0;
        [self.audioPlayer play];
    }
    [PXAlcoholFreeRecord setFreeDay:self.isAlcoholFreeDay date:self.referenceDate context:self.context];
}

- (void)pressedTabButton:(UIButton *)tabButton {
    if (!tabButton.selected) {
        for (UIButton *button in self.tabButtons) {
            button.selected = (button == tabButton);
        }
        self.panelType = tabButton.tag;
    }
}

- (IBAction)pageControlChanged:(UIPageControl *)pageControl {
    NSInteger previousPage = self.layout.currentPage;
    [self.layout scrollToPage:pageControl.currentPage animated:YES];
    // Restore previous page as the delegate handles it (otherwise it will jump)
    pageControl.currentPage = previousPage;
}

#pragma mark - Editing

- (void)setEditingAllowed:(BOOL)editingAllowed {
    _editingAllowed = editingAllowed;
    
    self.editButton.hidden = !editingAllowed;
}

- (IBAction)toggleEditing:(id)sender {
    [self setEditing:!self.isEditing animated:YES];
}

- (void)setEditing:(BOOL)editing {
    [self setEditing:editing animated:NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if (editing && !self.isEditingAllowed) {
        return;
    }
    _editing = editing;
    
    NSString *title = editing ? @"Done" : @"Edit";
    [self.editButton setTitle:title forState:UIControlStateNormal];
    
    void (^updateBlock)() = ^{
        for (PXDrinkOptionCell *cell in self.collectionView.visibleCells) {
            cell.editing = editing;
        }
    };
    if (animated) {
        [UIView animateWithDuration:0.7
                              delay:0.1
             usingSpringWithDamping:0.5
              initialSpringVelocity:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:updateBlock
                         completion:NULL];
    } else {
        updateBlock();
    }
    for (PXDrinkOptionCell *cell in self.collectionView.visibleCells) {
        cell.shaking = editing;
    }
}

#pragma mark - PXHorizontalPagingLayoutDelegate

- (void)horizontalPagingLayout:(PXHorizontalPagingLayout *)layout changedNumberOfPages:(NSInteger)numberOfPages {
    BOOL hasAdditionalPages = numberOfPages > 1;
    self.titleLabel.hidden = hasAdditionalPages;
    self.pageControl.hidden = !hasAdditionalPages;
    self.pageControl.numberOfPages = numberOfPages;
}

- (void)horizontalPagingLayout:(PXHorizontalPagingLayout *)layout changedCurrentPage:(NSInteger)currentPage {
    self.pageControl.currentPage = currentPage;
}

#pragma mark - PXDrinkOptionCellDelegate

- (void)drinkOptionCell:(PXDrinkOptionCell *)cell pressedDelete:(id)sender {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    if (indexPath) {
        PXDrinkRecord *drinkRecord = [self.fetchedResultsController objectAtIndexPath:indexPath];
        drinkRecord.favourite = @NO;
        [self.context save:nil];
        [drinkRecord saveToParse];
    }
}

#pragma mark - UICollectionViewDataSource

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return !self.isEditing;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PXDrinkRecord *drinkRecord = [self.fetchedResultsController objectAtIndexPath:indexPath];
    PXDrinkOptionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"drinkOptionCell" forIndexPath:indexPath];
    cell.editing = self.isEditing;
    cell.shaking = self.isEditing;
    cell.delegate = self;
    
    if (self.panelType == PXStandardPanelType) {
        cell.titleLabel.text = drinkRecord.drink.name;
    } else {
        cell.titleLabel.text = drinkRecord.type.name ?: drinkRecord.drink.name;
    }
    
    cell.sizeLabel.text = drinkRecord.serving.name;
    cell.abvLabel.text = [NSString stringWithFormat:@"ABV %.01f%%", drinkRecord.abv.floatValue];
    cell.iconImageView.image = [UIImage imageNamed:drinkRecord.iconName];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController {
    if (!_fetchedResultsController) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PXDrinkRecord"];
        switch (self.panelType) {
            case PXStandardPanelType:
                fetchRequest.predicate = [NSPredicate predicateWithFormat:@"date == nil && groupName == 'standardTemplate'"];
                fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"drink.index" ascending:YES]];
                break;
            case PXFavouritesPanelType:
                fetchRequest.predicate = [NSPredicate predicateWithFormat:@"date != nil && favourite == YES"];
                fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
                break;
            case PXRecentPanelType: {
                PXHorizontalPagingLayout *layout = (PXHorizontalPagingLayout *)self.collectionView.collectionViewLayout;
                NSInteger itemsPerPage = layout.numberOfColumns * layout.numberOfRows;
                fetchRequest.fetchLimit = itemsPerPage * PXRecentPageLimit;
                fetchRequest.predicate = [NSPredicate predicateWithFormat:@"date != nil"];
                fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
                break;
            }
        }
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.context sectionNameKeyPath:nil cacheName:nil];
        _fetchedResultsController.delegate = self;
        [self.fetchedResultsController performFetch:nil];
    }
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    self.changes = [[NSMutableArray alloc] init];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    NSMutableDictionary *change = [NSMutableDictionary dictionary];
    switch(type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    [self.changes addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.collectionView performBatchUpdates:^{
        for (NSDictionary *change in self.changes) {
            [change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                switch(type) {
                    case NSFetchedResultsChangeInsert:
                        [self.collectionView insertItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeDelete:
                        [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeUpdate:
                        [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                        break;
                    case NSFetchedResultsChangeMove:
                        [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                        break;
                }
            }];
        }
    } completion:^(BOOL finished) {
        self.changes = nil;
    }];
}

@end
