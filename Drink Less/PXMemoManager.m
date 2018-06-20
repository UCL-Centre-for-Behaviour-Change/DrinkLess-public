//
//  PXCoinStore.m
//  Hatchi
//
//  Created by Martin O'Hagan on 29/02/2012.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXMemoManager.h"

#define PXMemosArrayKey @"PXMemosArrayKey"
#define PXMemoCountKey @"PXMemoCountKey"

#define PXMemoWatchReminderArrayKey @"PXMemoWatchReminderArrayKey"
#define PXMemoRecordReminderArrayKey @"PXMemoRecordReminderArrayKey"
#define PXMemoRemindersCountKey @"PXMemoRemindersCountKey"

#define PXMemoLocalNotificationIDKey @"PXMemoLocalNotificationIDKey"
#define PXMemoLocalNotificationID @"PXMemoLocalNotificationID"

@interface PXMemoManager ()
@property (nonatomic, strong) NSMutableArray* memosArray;
@property (nonatomic) NSInteger memosCount;

@property (nonatomic, strong) NSMutableArray* memoWatchRemindersArray;
@property (nonatomic, strong) NSMutableArray* memoRecordRemindersArray;
@property (nonatomic) NSInteger memoRemindersCount;

@property (nonatomic, strong) NSArray* memoMessages;

@end

@implementation PXMemoManager

+(PXMemoManager*)sharedInstance
{
    static PXMemoManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [NSKeyedUnarchiver unarchiveObjectWithFile:[PXMemoManager pathToStoredCoinsAmount]];
        
        if (sharedInstance == nil) {
            sharedInstance = [[PXMemoManager alloc] init];
        }
        sharedInstance.memoRecordRemindersGlobalActive = [[[NSUserDefaults standardUserDefaults] objectForKey:PXMemoRecordReminderType] boolValue];
        sharedInstance.memoWatchRemindersGlobalActive = [[[NSUserDefaults standardUserDefaults] objectForKey:PXMemoWatchReminderType] boolValue];

    });
    return sharedInstance;
}

+ (NSString*)pathToStoredCoinsAmount{
    NSString * localDocumentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString * filePath = [localDocumentsDirectory stringByAppendingPathComponent:@"data.dat"];
    
    return filePath;
}

- (void)save {
    [NSKeyedArchiver archiveRootObject:self toFile:[PXMemoManager pathToStoredCoinsAmount]];
}

- (id)init {
    self = [super init];
    if (self) {
        self.memosArray = [[NSMutableArray alloc] init];
        self.memosCount = 0;

        self.memoRecordRemindersArray = [[NSMutableArray alloc] init];
        self.memoWatchRemindersArray = [[NSMutableArray alloc] init];
        self.memoRemindersCount = 0;
        self.memoMessages = @[@"Video Memo Reminder", @"Video Memo Reminder"]; // watchmessage, recordmessage
    }
    
    return self;
}

#pragma mark - lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [self init];
    if (self) {
        self.memosCount = [[aDecoder decodeObjectForKey:PXMemoCountKey] integerValue];
        self.memoRemindersCount = [[aDecoder decodeObjectForKey:PXMemoRemindersCountKey] integerValue];
        
        NSArray* memoArray = [[NSMutableArray alloc] initWithArray:[aDecoder decodeObjectForKey:PXMemosArrayKey]];
        
        NSArray* memoRecordReminder = [[NSMutableArray alloc] initWithArray:[aDecoder decodeObjectForKey:PXMemoRecordReminderArrayKey]];
        NSArray* memoWatchReminders = [[NSMutableArray alloc] initWithArray:[aDecoder decodeObjectForKey:PXMemoWatchReminderArrayKey]];
        
        for (NSDictionary* reminderDict in memoRecordReminder) {
            PXMemoReminder* reminder = [[PXMemoReminder alloc] initWithDict:reminderDict];
            [self.memoRecordRemindersArray addObject:reminder];
        }
        
        for (NSDictionary* reminderDict in memoWatchReminders) {
            PXMemoReminder* reminder = [[PXMemoReminder alloc] initWithDict:reminderDict];
            [self.memoWatchRemindersArray addObject:reminder];
        }
        
        for (NSDictionary* memoDict in memoArray) {
            PXMemo* memo = [[PXMemo alloc] initWithDict:memoDict];
            [self.memosArray addObject:memo];
        }
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:@(self.memosCount) forKey:PXMemoCountKey];
    [aCoder encodeObject:@(self.memoRemindersCount) forKey:PXMemoRemindersCountKey];
    
    NSMutableArray* memosToSave = [[NSMutableArray alloc] init];
    NSMutableArray* memoRecordRemindersToSave = [[NSMutableArray alloc] init];
    NSMutableArray* memoWatchRemindersToSave = [[NSMutableArray alloc] init];

    for (PXMemo* memo in self.memosArray) {
        [memosToSave addObject:[memo exportDict]];
    }

    for (PXMemoReminder* reminder in self.memoRecordRemindersArray) {
        [memoRecordRemindersToSave addObject:[reminder exportDict]];
    }
    
    for (PXMemoReminder* reminder in self.memoWatchRemindersArray) {
        [memoWatchRemindersToSave addObject:[reminder exportDict]];
    }

    [aCoder encodeObject:memosToSave forKey:PXMemosArrayKey];
    [aCoder encodeObject:memoRecordRemindersToSave forKey:PXMemoRecordReminderArrayKey];
    [aCoder encodeObject:memoWatchRemindersToSave forKey:PXMemoWatchReminderArrayKey];
}

#pragma mark Memo methods

- (void)setMemoRecordRemindersGlobalActive:(BOOL)memoRecordRemindersGlobalActive {
    _memoRecordRemindersGlobalActive = memoRecordRemindersGlobalActive;

    [self.memoRecordRemindersArray enumerateObjectsUsingBlock:^(PXMemoReminder* memoReminder, NSUInteger idx, BOOL *stop) {
        [[PXLocalNotificationsManager sharedInstance] removeLocalNotificationWithType:PXMemoRecordReminderType ID:memoReminder.reminderID];
    }];
    if (memoRecordRemindersGlobalActive) {
        [self.memoRecordRemindersArray enumerateObjectsUsingBlock:^(PXMemoReminder* memoReminder, NSUInteger idx, BOOL *stop) {
            if (memoReminder.isOn) {
                [[PXLocalNotificationsManager sharedInstance] addLocalNotificationForDate:memoReminder.reminderDate
                                                                                  message:self.memoMessages[memoReminder.reminderType]
                                                                                     type:PXMemoRecordReminderType
                                                                                       ID:memoReminder.reminderID];
            }
        }];
    }
}

- (void)setMemoWatchRemindersGlobalActive:(BOOL)memoWatchRemindersGlobalActive {
    _memoWatchRemindersGlobalActive = memoWatchRemindersGlobalActive;

    [self.memoWatchRemindersArray enumerateObjectsUsingBlock:^(PXMemoReminder* memoReminder, NSUInteger idx, BOOL *stop) {
        [[PXLocalNotificationsManager sharedInstance] removeLocalNotificationWithType:PXMemoWatchReminderType ID:memoReminder.reminderID];
    }];
    if (memoWatchRemindersGlobalActive) {
        [self.memoWatchRemindersArray enumerateObjectsUsingBlock:^(PXMemoReminder* memoReminder, NSUInteger idx, BOOL *stop) {
            if (memoReminder.isOn) {
                [[PXLocalNotificationsManager sharedInstance] addLocalNotificationForDate:memoReminder.reminderDate
                                                                                  message:self.memoMessages[memoReminder.reminderType]
                                                                                     type:PXMemoWatchReminderType
                                                                                       ID:memoReminder.reminderID];
            }
        }];
    }
}

- (void)addMemoWithFilePath:(NSString*)memoFilePath {
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
    });
    
    NSDate *date = [NSDate date];
    NSString *memoName = [dateFormatter stringFromDate:date];
    PXMemo *memo = [[PXMemo alloc] initWithFilePath:memoFilePath recordedDate:date memoName:memoName];
    [self.memosArray addObject:memo];
    [self save];
}

- (NSInteger)numberOfMemos {
    return self.memosArray.count;
}

- (void)deleteMemoAtIndex:(NSInteger)index {
    PXMemo* memo = [self memoAtIndex:index];
    
    NSError* error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:memo.filePath error:&error];
    
    [self.memosArray removeObject:memo];
    [self save];
}

- (PXMemo*)memoAtIndex:(NSInteger)index {
    if (index < self.memosArray.count) {
        return self.memosArray[index];
    } else {
        NSLog(@"Memo index: %li out of bounds!", (long)index);
    }
    
    return nil;
}

- (void)saveMemoVideoAtPath:(NSURL*)videoFilePath {
    
    //Create memos folder in the documents directory if it does not exist
    NSError* error = nil;
    NSString *dataPath = [[self applicationDocumentsDirectory].path stringByAppendingPathComponent:@"/memos"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error];
    }

    NSString* fileName = [NSString stringWithFormat:@"memos/memo_%li.mov", (long)self.memosCount];
    self.memosCount++;
    NSString* extraPathComponent = [NSString stringWithFormat:@"%@",fileName];
    NSString *saveToPath = [[self applicationDocumentsDirectory].path
                            stringByAppendingPathComponent:extraPathComponent];
    
    //Save the movie
    [[NSFileManager defaultManager] copyItemAtURL:videoFilePath toURL:[NSURL fileURLWithPath:saveToPath] error:&error];
    [[PXMemoManager sharedInstance] addMemoWithFilePath:saveToPath];
}

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

#pragma mark Memo Reminders methods

- (void)addMemoReminder:(NSDate*)date memoReminderType:(PXMemoReminderType)type isOn:(BOOL)on {
    NSString* ID = [NSString stringWithFormat:@"%@%li", PXMemoLocalNotificationID, (long)self.memoRemindersCount];
    PXMemoReminder* memoReminder = [[PXMemoReminder alloc] initWithID:ID date:date type:type isOn:on];
    self.memoRemindersCount++;

    BOOL enabled = NO;
    if (type == PXMemoReminderRecordType) {
        [self.memoRecordRemindersArray addObject:memoReminder];
        enabled = self.memoRecordRemindersGlobalActive;
    } else if (type == PXMemoReminderWatchType) {
        [self.memoWatchRemindersArray addObject:memoReminder];
        enabled = self.memoWatchRemindersGlobalActive;
    }
    
    if (memoReminder.isOn && enabled) {
        [[PXLocalNotificationsManager sharedInstance] addLocalNotificationForDate:memoReminder.reminderDate
                                                                          message:self.memoMessages[memoReminder.reminderType]
                                                                             type:[self reminderTypeStringForType:memoReminder.reminderType]
                                                                               ID:memoReminder.reminderID];
    } else {
        [[PXLocalNotificationsManager sharedInstance] removeLocalNotificationWithType:[self reminderTypeStringForType:memoReminder.reminderType] ID:memoReminder.reminderID];
    }
    
    [self save];
}

- (void)removeMemoReminderAtIndex:(NSInteger)index forType:(PXMemoReminderType)reminderType {
    PXMemoReminder* memoReminder = [self memoReminderAtIndex:index forType:reminderType];
    
    [[PXLocalNotificationsManager sharedInstance] removeLocalNotificationWithType:[self reminderTypeStringForType:memoReminder.reminderType] ID:memoReminder.reminderID];
    
    if (reminderType == PXMemoReminderRecordType) {
        [self.memoRecordRemindersArray removeObjectAtIndex:index];
    } else if (reminderType == PXMemoReminderWatchType) {
        [self.memoWatchRemindersArray removeObjectAtIndex:index];
    }

    [self save];
}

- (void)updateMemoReminder:(PXMemoReminder*)reminder withDate:(NSDate*)newDate newIsOn:(BOOL)isOn {
    reminder.reminderDate = newDate;

    BOOL enabled = NO;
    if (reminder.reminderType == PXMemoReminderRecordType) {
        enabled = self.memoRecordRemindersGlobalActive;
    } else if (reminder.reminderType == PXMemoReminderWatchType) {
        enabled = self.memoWatchRemindersGlobalActive;
    }

    if (reminder.isOn != isOn) {
        reminder.isOn = isOn;
        [[PXLocalNotificationsManager sharedInstance] removeLocalNotificationWithType:[self reminderTypeStringForType:reminder.reminderType] ID:reminder.reminderID];
        
        if (reminder.isOn && enabled) {
            [[PXLocalNotificationsManager sharedInstance] addLocalNotificationForDate:reminder.reminderDate
                                                                              message:self.memoMessages[reminder.reminderType]
                                                                                 type:[self reminderTypeStringForType:reminder.reminderType]
                                                                                   ID:reminder.reminderID];
        }
    }
}

- (NSInteger)numberOfMemoRemindersForType:(PXMemoReminderType)type {
    NSDate *now = [NSDate date];
    
    if (type == PXMemoReminderRecordType) {

        
        for(PXMemoReminder *recordMemoReminder in self.memoRecordRemindersArray)
        {
        
            if ([now laterDate:recordMemoReminder.reminderDate] == now) {
                
                [self.memoRecordRemindersArray removeObject:recordMemoReminder];
            }
            
        }
        return self.memoRecordRemindersArray.count;
        
    } else if (type == PXMemoReminderWatchType) {
        
        for(PXMemoReminder *watchMemoReminder in self.memoWatchRemindersArray)
        {
        
            if ([now laterDate:watchMemoReminder.reminderDate] == now) {
                [self.memoWatchRemindersArray removeObject:watchMemoReminder];
            }
            
        }
        
        
        return self.memoWatchRemindersArray.count;
    }
    
    return 0;
}

- (PXMemoReminder*)memoReminderAtIndex:(NSInteger)index forType:(PXMemoReminderType)type{
    if (type == PXMemoReminderRecordType) {
        if (index < self.memoRecordRemindersArray.count) {
            return self.memoRecordRemindersArray[index];
        } else {
            NSLog(@"Memo record reminder index: %li out of bounds!", (long)index);
        }
    } else if (type == PXMemoReminderWatchType) {
        if (index < self.memoWatchRemindersArray.count) {
            return self.memoWatchRemindersArray[index];
        } else {
            NSLog(@"Memo watch reminder index: %li out of bounds!", (long)index);
        }
    }
    
    return nil;
}

- (NSString*)reminderTypeStringForType:(PXMemoReminderType)reminderType {
    if (reminderType == PXMemoReminderRecordType) {
        return PXMemoRecordReminderType;
    } else if (reminderType == PXMemoReminderWatchType) {
        return PXMemoWatchReminderType;
    }
    
    return @"";
}

@end
