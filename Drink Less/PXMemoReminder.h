//
//  PXMemoReminder.h
//  drinkless
//
//  Created by Chris on 29/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PXMemoReminderType) {
    PXMemoReminderWatchType = 0,
    PXMemoReminderRecordType = 1
};

@interface PXMemoReminder : NSObject

@property (nonatomic, strong) NSString* reminderID;
@property (nonatomic, strong) NSDate* reminderDate;
@property (nonatomic) PXMemoReminderType reminderType;
@property (nonatomic) BOOL isOn;

- (id)initWithDict:(NSDictionary*)dict;
- (id)initWithID:(NSString*)ID date:(NSDate*)date type:(PXMemoReminderType)type isOn:(BOOL)on;
- (NSDictionary*)exportDict;


@end
