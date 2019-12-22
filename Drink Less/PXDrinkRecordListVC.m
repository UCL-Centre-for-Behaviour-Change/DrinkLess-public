//
//  PXDrinkRecordListVC.m
//  drinkless
//
//  Created by Edward Warrender on 11/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "drinkless-Swift.h"
#import "PXDrinkRecordListVC.h"
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


@interface PXDrinkRecordListVC () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet PXDateStepControl *dateStepControl;
@property (weak, nonatomic) IBOutlet PXPlaceholderViewRenamed *alcoholFreePlaceholderView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *makePlanCont;
@property (weak, nonatomic) IBOutlet UIView *existingPlanCont;
@property (weak, nonatomic) IBOutlet UIImageView *existingPlanIcon;
@property (weak, nonatomic) IBOutlet UILabel *existingPlanTextLbl;
@property (weak, nonatomic) IBOutlet UILabel *existingPlanReminderLbl;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *drinkingSectionHConstr;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *planSectionHConstr;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *drinksTableHConstr;


@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSFetchedResultsController *addedDrinksListener;
@property (nonatomic, getter = isAlcoholFreeDay) BOOL alcoholFreeDay;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) NSString *diaryComment;
@property (nonatomic) BOOL hasDiaryComment;
@property (weak, nonatomic) IBOutlet UIButton *editTableBtn;

@property (nonatomic, strong) CalendarDate *calendarDate;
@property (nonatomic, strong) MyPlanRecord *myPlan;  // nil if none for this date

@end

@implementation PXDrinkRecordListVC


//////////////////////////////////////////////////////////
// MARK: - Life Cycle
//////////////////////////////////////////////////////////


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Drinking diary";
    
    UIFont *font = self.alcoholFreePlaceholderView.titleLabel.font;
    font = [UIFont fontWithName:font.fontName size:24.0];
    self.alcoholFreePlaceholderView.titleLabel.font = font;
    
    self.dateStepControl.date = _date;
    self.dateStepControl.allowsFutureDates = YES;
    
    self.tableView.allowsSelectionDuringEditing = YES;
    
    self.existingPlanIcon.layer.cornerRadius = 50;
    self.existingPlanIcon.layer.masksToBounds = true;
    self.existingPlanIcon.layer.borderColor = [UIColor drinkLessLightGreyColor].CGColor;
    
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
    [self refreshDataAndViewsAnimated:NO];
}


//---------------------------------------------------------------------

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:MakePlanVC.class]) {
        MakePlanVC *vc = (MakePlanVC *)segue.destinationViewController;
        CalendarDate *calDate = [[CalendarDate alloc] initWithDate:self.date timeZone:NSCalendar.currentCalendar.timeZone];
        vc.currentCalDate = calDate;
    }
}


- (void)_updateDataVars {
    // If a plan record exists then show that. Otherwise today or in the future, show the make a plan cont
    self.calendarDate = [[CalendarDate alloc] initWithDate:self.date  timeZone:NSCalendar.currentCalendar.timeZone];
    self.myPlan = [MyPlanRecord fetchRecordFor:self.calendarDate context:self.context];
    
    NSLog(@"Current calendarDate: %@, myPlan: %@", self.calendarDate, self.myPlan);
}

//---------------------------------------------------------------------

- (void)refreshDataAndViewsAnimated:(BOOL)animated {
    [self _updateDataVars];

    
    [self.tableView reloadData];
    CGRect f = self.tableView.frame;
    f.size.height = 10000; // make sure its enough to show them all
    self.tableView.frame = f;
    [self.tableView reloadData];
    
    UITableViewHeaderFooterView *sectionHeaderView = [self.tableView headerViewForSection:0];
    sectionHeaderView.textLabel.text = [self totalUnitsForDayText];
    
    NSDate *date = [NSDate strictDateFromDate:self.date];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date == %@", date];
    PXMoodDiary *moodDiary = [[PXUserMoodDiaries loadMoodDiaries].moodDiaries filteredArrayUsingPredicate:predicate].firstObject;
    self.diaryComment = moodDiary.comment;
    
    BOOL hasDrinks = (self.fetchedResultsController.fetchedObjects.count > 0);
    BOOL hasPlan = (self.myPlan != nil);
    
    /////////////////////////////////////////
    // DRINKS SECTION
    /////////////////////////////////////////
    
    // Don't show either in the future
    BOOL isFuture = [self.date timeIntervalSinceDate:NSDate.strictDateFromToday] > 0;
    self.tableView.hidden = !hasDrinks;// they want "future" drinks to be visible || isFuture;
    self.alcoholFreePlaceholderView.hidden = hasDrinks || isFuture;
    
    NSMutableAttributedString *footer = nil;
    if (self.hasDiaryComment) {
        footer = [[NSMutableAttributedString alloc] initWithString:self.diaryComment];
        NSAttributedString *comments = [[NSAttributedString alloc] initWithString:@"Comments:\n" attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:self.alcoholFreePlaceholderView.footerLabel.font.pointSize]}];
        [footer insertAttributedString:comments atIndex:0];
    }
    
    self.alcoholFreeDay = [PXAlcoholFreeRecord fetchFreeRecordsForCalendarDate:self.date context:self.context].count;
    UIImage *image = self.isAlcoholFreeDay ? [UIImage imageNamed:@"goal-hit"] : nil;
    BOOL SMisHigh = [PXGroupsManager sharedManager].highSM.boolValue;
    NSString *title = self.isAlcoholFreeDay ? nil : @"You haven’t recorded any alcoholic drinks for this day.";
    NSString *subtitle = self.isAlcoholFreeDay ? SMisHigh ? @"Keep up the good work!" : @"" : @"Having trouble remembering? It might help to look at your calendar or diary for notes of what you were doing. Or perhaps your text messages or emails can jog your memory.";
    [self.alcoholFreePlaceholderView setImage:SMisHigh ? image : nil
                             title:title
                          subtitle:subtitle
                       buttonTitle:@"Alcohol Free Day"
                            footer:footer
                             solid:self.isAlcoholFreeDay
                            target:self
                            action:@selector(toggleAlcoholFreeDay)];
    
    /////////////////////////////////////////
    // PLAN SECTION
    /////////////////////////////////////////
    
    self.existingPlanCont.hidden = YES;
    self.makePlanCont.hidden = YES;
    
    CalendarDate *nowCalDate = [[[CalendarDate alloc] initWithDate:NSDate.date timeZone:NSCalendar.currentCalendar.timeZone] withTruncatedTimeComponents];
    
    if (hasPlan) {
        self.existingPlanCont.hidden = NO;
        [self.existingPlanCont.superview bringSubviewToFront:self.existingPlanCont];
        self.existingPlanTextLbl.text = self.myPlan.label;
        self.existingPlanIcon.image = self.myPlan.iconImg;
        
        // TODO: change to notification ID
        if (self.myPlan.reminderTime != nil) {
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setAMSymbol:@"am"];
            [df setPMSymbol:@"pm"];
            df.dateFormat = @"h:mma";
            NSTimeZone *tz = [NSTimeZone timeZoneWithName:self.myPlan.timezoneStr];
            NSDate *reminderTimeCurrCal = [self.myPlan.reminderTime dateInCurrentCalendarsTimezoneMatchingComponentsToThisOneInTimezoneIncludingTime:tz];
            self.existingPlanReminderLbl.text = [NSString stringWithFormat:@"Reminder set for %@", [df stringFromDate:reminderTimeCurrCal]];
        } else {
            self.existingPlanReminderLbl.text = @"No reminder is set";
        }
        
        // TODO: Edit??x
        
    } else if ([self.calendarDate compare:nowCalDate] != NSOrderedAscending) {
        self.makePlanCont.hidden = NO;
        [self.makePlanCont.superview bringSubviewToFront:self.makePlanCont];
        
    }
    
    /////////////////////////////////////////
    // SIZE UPDATES
    /////////////////////////////////////////
    void (^doIt)(void) = ^{
        
        // Drinks section
        CGFloat newH = 0;
        if (!self.tableView.hidden) {
            newH = self.tableView.contentSize.height;
            self.drinksTableHConstr.constant = newH;
        } else if (!self.alcoholFreePlaceholderView.hidden) {
            newH = self.alcoholFreePlaceholderView.frame.size.height;
        } else {
            newH = 0;
        }
        self.drinkingSectionHConstr.constant = newH;
        
        // Plan section
        newH = 0;
        if (!self.makePlanCont.hidden) {
            newH = self.makePlanCont.frame.size.height;
        } else if (!self.existingPlanCont.hidden) {
            newH = self.existingPlanCont.frame.size.height;
        }
        self.planSectionHConstr.constant = newH;
    };
    
    [self.view setNeedsUpdateConstraints];
    [self.view setNeedsLayout];
    if (animated) {
        
        [UIView
         animateWithDuration:0.5
         animations:^{
             doIt();
             [self.view updateConstraintsIfNeeded];
             [self.view layoutIfNeeded];
         }
         completion:nil];
    } else {
        doIt();
        [self.view updateConstraintsIfNeeded];
        [self.view layoutIfNeeded];
    }
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
        [self refreshDataAndViewsAnimated:YES];
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
    
    // Close edit mode
    if (self.tableView.editing) {
        [self editTable:nil];
    }
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
    
    [self refreshDataAndViewsAnimated:YES];
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
    
    [self refreshDataAndViewsAnimated:YES];
    
    return;
    
    // We had to get rid of animations when the TZ complication came in. In short, the NSFRC no longer can be used as simply as before. We've had to do a workaround which messes up the animations
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
    [self refreshDataAndViewsAnimated:YES];
}

#pragma mark - Actions

- (void)toggleAlcoholFreeDay {
    self.alcoholFreeDay = !self.isAlcoholFreeDay;
    [PXAlcoholFreeRecord setFreeDay:self.isAlcoholFreeDay date:self.date context:self.context];
    
    [UIView animateWithDuration:0.7 delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.0 options:0 animations:^{
        [self refreshDataAndViewsAnimated:NO];
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
    [self refreshDataAndViewsAnimated:NO];
}

- (IBAction)showInfo:(id)sender {
    [PXInfoViewController showResource:@"calendar-day" fromViewController:self];
}

- (IBAction)editTable:(id)sender {
    [self.editTableBtn setTitle:_tableView.editing?@"Edit":@"Done" forState:UIControlStateNormal];
    [_tableView setEditing:!_tableView.editing animated:YES];
}

- (IBAction)editPlanPressed:(id)sender {
    // Only edit plan if in the future
    if ([self.date timeIntervalSinceDate:NSDate.strictDateFromToday] >= 0) {
        [self performSegueWithIdentifier:@"PlanDetailsSegue" sender:nil];
    }
}

//////////////////////////////////////////////////////////
// MARK: - Additional Privates
//////////////////////////////////////////////////////////

@end
