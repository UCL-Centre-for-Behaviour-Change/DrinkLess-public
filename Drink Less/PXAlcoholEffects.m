//
//  PXAlcoholEffects.m
//  drinkless
//
//  Created by Edward Warrender on 03/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXAlcoholEffects.h"
#import "PXUserMoodDiaries.h"
#import "PXMoodDiary.h"
#import "PXDrinkRecord+Extras.h"
#import "PXIntroManager.h"
#import "PXCoreDataManager.h"

@implementation PXAlcoholEffects

- (id)init {
    if (self = [super init]) {
        NSManagedObjectContext *context = [PXCoreDataManager sharedManager].managedObjectContext;
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"AlcoholEffects" ofType:@"plist"];
        _information = [NSArray arrayWithContentsOfFile:path];
        
        PXUserMoodDiaries *userMoodDiaries = [PXUserMoodDiaries loadMoodDiaries];
        if (userMoodDiaries.moodDiaries.count == 0) {
            return nil;
        }
        NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
        NSArray *moodDiaries = [userMoodDiaries.moodDiaries sortedArrayUsingDescriptors:@[sortByDate]];
        
        CGFloat moodAfterDrinking = 0.0;
        CGFloat moodAfterNotDrinking = 0.0;
        CGFloat productivityAfterDrinking = 0.0;
        CGFloat productivityAfterNotDrinking = 0.0;
        CGFloat clarityAfterDrinking = 0.0;
        CGFloat clarityAfterNotDrinking = 0.0;
        CGFloat sleepAfterDrinking = 0.0;
        CGFloat sleepAfterNotDrinking = 0.0;
        
        NSInteger drinkingDays = 0;
        NSInteger notDrinkingDays = 0;
        
        for (PXMoodDiary *diary in moodDiaries) {
            NSCalendar *calendar = [NSCalendar currentCalendar];
            NSCalendarUnit noTimeComponents = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
            NSDateComponents *dateComponents = [calendar components:noTimeComponents fromDate:diary.date];
            NSDate *toDate = [calendar dateFromComponents:dateComponents];
            
            NSDateComponents *previousDayComponents = [[NSDateComponents alloc] init];
            previousDayComponents.day = -1;
            NSDate *fromDate = [calendar dateByAddingComponents:previousDayComponents toDate:toDate options:0];
            
            CGFloat units = 0.0;
            NSArray *drinkRecords = [PXDrinkRecord fetchDrinkRecordsFromCalendarDate:fromDate toCalendarDate:toDate context:context];
            for (PXDrinkRecord *record in drinkRecords) {
                units += record.totalUnits.floatValue;
            }
            BOOL isFemale = [PXIntroManager sharedManager].gender.boolValue;
            CGFloat unitsLimit = isFemale ? 6 : 6;  //governemnt guidelines changed so same for m/f
            
            if (units > unitsLimit) {
                moodAfterDrinking += diary.happiness.floatValue;
                productivityAfterDrinking += diary.productivity.floatValue;
                clarityAfterDrinking += diary.clearHeaded.floatValue;
                sleepAfterDrinking += diary.sleep.floatValue;
                drinkingDays++;
            }
            else {
                moodAfterNotDrinking += diary.happiness.floatValue;
                productivityAfterNotDrinking += diary.productivity.floatValue;
                clarityAfterNotDrinking += diary.clearHeaded.floatValue;
                sleepAfterNotDrinking += diary.sleep.floatValue;
                notDrinkingDays++;
            }
        }
        
        // Calculate average
        moodAfterDrinking            /= drinkingDays;
        productivityAfterDrinking    /= drinkingDays;
        clarityAfterDrinking         /= drinkingDays;
        sleepAfterDrinking           /= drinkingDays;
        moodAfterNotDrinking         /= notDrinkingDays;
        productivityAfterNotDrinking /= notDrinkingDays;
        clarityAfterNotDrinking      /= notDrinkingDays;
        sleepAfterNotDrinking        /= notDrinkingDays;
        
        _afterDrinking = @{@(PXAlcoholEffectTypeMood):         @(moodAfterDrinking),
                           @(PXAlcoholEffectTypeProductivity): @(productivityAfterDrinking),
                           @(PXAlcoholEffectTypeClarity):      @(clarityAfterDrinking),
                           @(PXAlcoholEffectTypeSleep):        @(sleepAfterDrinking)};
        
        _afterNotDrinking = @{@(PXAlcoholEffectTypeMood):         @(moodAfterNotDrinking),
                              @(PXAlcoholEffectTypeProductivity): @(productivityAfterNotDrinking),
                              @(PXAlcoholEffectTypeClarity):      @(clarityAfterNotDrinking),
                              @(PXAlcoholEffectTypeSleep):        @(sleepAfterNotDrinking)};
    }
    return self;
}

@end
