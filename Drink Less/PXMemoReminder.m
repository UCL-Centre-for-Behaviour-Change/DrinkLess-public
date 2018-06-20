//
//  PXMemoReminder.m
//  drinkless
//
//  Created by Chris on 29/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXMemoReminder.h"

@implementation PXMemoReminder

- (id)initWithDict:(NSDictionary*)dict {
    self = [super init];
    if (self) {
        self.reminderID = dict[@"ID"];
        self.reminderDate = dict[@"date"];
        self.reminderType = [dict[@"type"] integerValue];
        self.isOn = [dict[@"on"] integerValue];
    }
    
    return self;
}

- (id)initWithID:(NSString*)ID date:(NSDate*)date type:(PXMemoReminderType)type isOn:(BOOL)on {
    self = [super init];
    if (self) {
        self.reminderID = ID;
        self.reminderDate = date;
        self.reminderType = type;
        self.isOn = on;
    }
    
    return self;
}

- (NSDictionary*)exportDict {
    return @{@"ID"   : self.reminderID,
             @"date" : self.reminderDate,
             @"type" : @(self.reminderType),
             @"on"   : @(self.isOn)};
}

@end
