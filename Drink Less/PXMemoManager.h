//
//  PXCoinStore.h
//  Hatchi2
//
//  Created by Martin O'Hagan on 29/02/2012.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>
#import "PXMemo.h"
#import "PXMemoReminder.h"
#import "PXLocalNotificationsManager.h"

@interface PXMemoManager : NSObject <NSCoding>

@property (nonatomic) BOOL memoRecordRemindersGlobalActive;
@property (nonatomic) BOOL memoWatchRemindersGlobalActive;

+ (PXMemoManager*)sharedInstance;

- (void)addMemoWithFilePath:(NSString*)memoFilePath;
- (void)deleteMemoAtIndex:(NSInteger)index;
- (NSInteger)numberOfMemos;
- (PXMemo*)memoAtIndex:(NSInteger)index;
- (void)saveMemoVideoAtPath:(NSString*)videoFilePath;

- (void)addMemoReminder:(NSDate*)date memoReminderType:(PXMemoReminderType)type isOn:(BOOL)on;
- (void)removeMemoReminderAtIndex:(NSInteger)index forType:(PXMemoReminderType)reminderType;
- (void)updateMemoReminder:(PXMemoReminder*)reminder withDate:(NSDate*)newDate newIsOn:(BOOL)on;

- (NSInteger)numberOfMemoRemindersForType:(PXMemoReminderType)type;
- (PXMemoReminder*)memoReminderAtIndex:(NSInteger)index forType:(PXMemoReminderType)type;

- (void)save;

@end
