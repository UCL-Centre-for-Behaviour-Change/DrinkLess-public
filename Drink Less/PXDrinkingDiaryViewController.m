//
//  PXDrinkingDiaryViewController.m
//  drinkless
//
//  Created by Edward Warrender on 11/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXDrinkingDiaryViewController.h"
#import <CoreData/CoreData.h>
#import <AVFoundation/AVFoundation.h>
#import "PXDrinkRecord+Extras.h"
#import "PXDrink.h"
#import "PXCoreDataManager.h"
#import "PXDrinkRecordViewController.h"
#import "PXDateStepControl.h"
#import "PXDrinkLogCell.h"
#import "PXDrinkServing.h"
#import "PXDrinkType.h"
#import "PXAlcoholFreeRecord+Extras.h"
#import "PXPlaceholderViewRenamed.h"
#import "PXTabBarController.h"
#import "PXDailyTaskManager.h"
#import "PXGroupsManager.h"
#import "PXUserMoodDiaries.h"
#import "PXMoodDiary.h"
#import "UIViewController+Swipe.h"
#import "PXInfoViewController.h"

@interface PXDrinkingDiaryViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet PXDateStepControl *dateStepControl;
@property (weak, nonatomic) IBOutlet PXPlaceholderViewRenamed *placeholderView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSFetchedResultsController *addedDrinksListener;
@property (nonatomic, getter = isAlcoholFreeDay) BOOL alcoholFreeDay;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) NSString *diaryComment;
@property (nonatomic) BOOL hasDiaryComment;

@end

@implementation PXDrinkingDiaryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Drinking diary";
    
    UIFont *font = self.placeholderView.titleLabel.font;
    font = [UIFont fontWithName:font.fontName size:24.0];
    self.placeholderView.titleLabel.font = font;
    
    self.dateStepControl.date = _date;
    
    __weak typeof(self) weakSelf = self;
    [self addSwipeWithCallback:^(UISwipeGestureRecognizerDirection direction) {
        if (direction == UISwipeGestureRecognizerDirectionLeft) {
            [weakSelf.dateStepControl increase];
        } else if (direction == UISwipeGestureRecognizerDirectionRight) {
            [weakSelf.dateStepControl decrease];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Init audio only if enabled
    self.audioPlayer = nil;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enable-sounds"]) {
        NSURL *audioURL = [[NSBundle mainBundle] URLForResource:@"DrinkSuccess" withExtension:@"wav"];
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.audioPlayer prepareToPlay];
        });
    }
    
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updatePlaceholder];
}

- (void)updatePlaceholder {
    UITableViewHeaderFooterView *sectionHeaderView = [self.tableView headerViewForSection:0];
    sectionHeaderView.textLabel.text = [self totalUnitsForDayText];
    
    NSDate *date = [NSDate strictDateFromDate:self.date];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date == %@", date];
    PXMoodDiary *moodDiary = [[PXUserMoodDiaries loadMoodDiaries].moodDiaries filteredArrayUsingPredicate:predicate].firstObject;
    self.diaryComment = moodDiary.comment;
    
    BOOL noObjects = (self.fetchedResultsController.fetchedObjects.count == 0);
    self.tableView.hidden = noObjects;
    self.placeholderView.hidden = !noObjects;
    
    NSMutableAttributedString *footer = nil;
    if (self.hasDiaryComment) {
        footer = [[NSMutableAttributedString alloc] initWithString:self.diaryComment];
        NSAttributedString *comments = [[NSAttributedString alloc] initWithString:@"Comments:\n" attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:self.placeholderView.footerLabel.font.pointSize]}];
        [footer insertAttributedString:comments atIndex:0];
    }
    
    self.alcoholFreeDay = [PXAlcoholFreeRecord fetchFreeRecordsForCalendarDate:self.date context:self.context].count;
    UIImage *image = self.isAlcoholFreeDay ? [UIImage imageNamed:@"goal-hit"] : nil;
    BOOL SMisHigh = [PXGroupsManager sharedManager].highSM.boolValue;
    NSString *title = self.isAlcoholFreeDay ? nil : @"You haven’t recorded any alcoholic drinks for this day.";
    NSString *subtitle = self.isAlcoholFreeDay ? SMisHigh ? @"Keep up the good work!" : @"" : @"Having trouble remembering? It might help to look at your calendar or diary for notes of what you were doing. Or perhaps your text messages or emails can jog your memory.";
    [self.placeholderView setImage:SMisHigh ? image : nil
                             title:title
                          subtitle:subtitle
                       buttonTitle:@"Alcohol Free Day"
                            footer:footer
                             solid:self.isAlcoholFreeDay
                            target:self
                            action:@selector(toggleAlcoholFreeDay)];
}

- (NSString *)totalUnitsForDayText {
    CGFloat totalUnits = 0.0;
    for (PXDrinkRecord *drinkRecord in self.fetchedResultsController.fetchedObjects) {
        totalUnits += drinkRecord.totalUnits.floatValue;
    }
    
    BOOL SMisHigh = [PXGroupsManager sharedManager].highSM.boolValue;
    
    if (SMisHigh) {
        return [NSString stringWithFormat:@"Total Units: %.1f", totalUnits];
    } else {
        return @"";
    }

    
}

#pragma mark - Properties

- (BOOL)hasDiaryComment {
    return self.diaryComment.length != 0;
}

- (NSDate *)date {
    return self.dateStepControl.date;
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self totalUnitsForDayText];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (self.hasDiaryComment) {
        return [@"\nCOMMENTS\n" stringByAppendingString:self.diaryComment];
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        PXDrinkRecord *drinkRecord = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [drinkRecord deleteFromParse];
        [self.context deleteObject:drinkRecord];
        [self.context save:nil];
        [self.tableView reloadData];
        [self updatePlaceholder];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PXDrinkLogCell *cell = [tableView dequeueReusableCellWithIdentifier:@"logCell" forIndexPath:indexPath];
    PXDrinkRecord *drinkRecord = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.iconImageView.image = [UIImage imageNamed:drinkRecord.iconName];
    cell.nameLabel.text = drinkRecord.type ? drinkRecord.type.name : drinkRecord.drink.name;
    cell.servingLabel.text = drinkRecord.serving.name;
    
    NSString *stats = [NSString stringWithFormat:@"%.1f Units", drinkRecord.totalUnits.floatValue];
    stats = [stats stringByAppendingFormat:@", %.f Cals", drinkRecord.totalCalories.floatValue];
    
    if (![PXGroupsManager sharedManager].highSM.boolValue) {
        stats = @" ";
    }
    cell.statsLabel.text = stats;
    
    cell.quantityLabel.text = [NSString stringWithFormat:@"x%@", drinkRecord.quantity.stringValue];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PXDrinkRecordViewController *drinkRecordVC = [PXDrinkRecordViewController recordViewController];
    drinkRecordVC.context = [PXCoreDataManager temporaryContext];
    PXDrinkRecord *drinkRecord = [self.fetchedResultsController objectAtIndexPath:indexPath];
    drinkRecordVC.drinkRecord = (PXDrinkRecord *)[drinkRecordVC.context objectWithID:drinkRecord.objectID];
    [self.navigationController pushViewController:drinkRecordVC animated:YES];
}

#pragma mark - NSFetchedResultsController


- (NSFetchedResultsController *)fetchedResultsController {
    if (!_fetchedResultsController) {
        NSError *error = nil;

    // Issue here: Our hack is to get the drinks with the calendar date specified through our timezone calcs, and then create a predicate that grabs those specific ones. But this doesn't register additions! So this would require a major rethink or we for now will just have another listener on the current date
    
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        fetchRequest.entity = [NSEntityDescription entityForName:@"PXDrinkRecord" inManagedObjectContext:self.context];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"date == %@", self.date];
        fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO]];
        _addedDrinksListener = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.context sectionNameKeyPath:nil cacheName:nil];
        _addedDrinksListener.delegate = self;
        if (![_addedDrinksListener performFetch:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        
        NSFetchRequest *fetchRequest2 = [PXDrinkRecord fetchRequestForCalendarDate:self.date context:self.context];
        fetchRequest2.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO]];

        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest2 managedObjectContext:self.context sectionNameKeyPath:nil cacheName:nil];
        _fetchedResultsController.delegate = self;
        if (![_fetchedResultsController performFetch:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    return _fetchedResultsController;
}
- (void)_resetFetchedResultsPredicate
{
    NSError *error;
    self.fetchedResultsController.fetchRequest.predicate = [PXDrinkRecord fetchRequestPredicateForCalendarDate:self.date context:self.context];
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
//    [self.tableView beginUpdates];
    if (controller == _addedDrinksListener) {
        [self _resetFetchedResultsPredicate];
    }
    
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    if (controller == _addedDrinksListener) return;  // this is just a dummy to trigger the main one
    
    [self.tableView reloadData];
    return;

    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    if (controller == _addedDrinksListener) return;  // this is just a dummy to trigger the main one
    
    UITableView *tableView = self.tableView;
    
    [self.tableView reloadData];
    return;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if (controller == _addedDrinksListener) return;  // this is just a dummy to trigger the main one
    
//    [self.tableView endUpdates];
    [self updatePlaceholder];
}

#pragma mark - Actions

- (void)toggleAlcoholFreeDay {
    self.alcoholFreeDay = !self.isAlcoholFreeDay;
    [PXAlcoholFreeRecord setFreeDay:self.isAlcoholFreeDay date:self.date context:self.context];
    
    [UIView animateWithDuration:0.7 delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.0 options:0 animations:^{
        [self updatePlaceholder];
    } completion:nil];
    
    if (self.isAlcoholFreeDay) {
        self.audioPlayer.currentTime = 0;
        [self.audioPlayer play];
    }
}

- (IBAction)tappedPlaceholder:(id)sender {
    if (!self.isAlcoholFreeDay) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PXShowDrinksPanelNotification object:nil];
    }
}

- (IBAction)changedDateStepControl:(id)sender {
    _fetchedResultsController = nil; // reset BOTH fetchConns
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    [self updatePlaceholder];
    [self.tableView reloadData];
}

#pragma mark - Actions

- (IBAction)unwindWithSegue:(UIStoryboardSegue *)segue {
    if ([segue.identifier isEqualToString:@"save"]) {
        // User saved the drink record
    }
}

- (IBAction)showInfo:(id)sender {
    [PXInfoViewController showResource:@"calendar-day" fromViewController:self];
}

@end
