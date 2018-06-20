//
//  PXActionPlan.m
//  drinkless
//
//  Created by Edward Warrender on 16/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXActionPlan.h"
#import "PXUserActionPlans.h"

static NSString *const PXIfTextKey = @"ifText";
static NSString *const PXThenTextKey = @"thenText";
static NSString *const PXParseUpdatedKey = @"parseUpdated";

@implementation PXActionPlan

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.ifText = [aDecoder decodeObjectForKey:PXIfTextKey];
        self.thenText = [aDecoder decodeObjectForKey:PXThenTextKey];
        self.parseUpdated = [aDecoder decodeBoolForKey:PXParseUpdatedKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.ifText forKey:PXIfTextKey];
    [aCoder encodeObject:self.thenText forKey:PXThenTextKey];
    [aCoder encodeBool:self.isParseUpdated forKey:PXParseUpdatedKey];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    PXActionPlan *actionPlan = [[self class] allocWithZone:zone];
    actionPlan.ifText = self.ifText.copy;
    actionPlan.thenText = self.thenText.copy;
    return actionPlan;
}

#pragma mark - Parse

- (void)saveAndLogToParse:(PXUserActionPlans *)userActionPlans {
    self.parseUpdated = NO;
    [userActionPlans save];
    
    PFObject *object = [PFObject objectWithClassName:NSStringFromClass(self.class)];
    object.objectId = self.parseObjectId;
    object[@"user"] = [PFUser currentUser];
    if (self.ifText)   object[@"if"]   = self.ifText;
    if (self.thenText) object[@"then"] = self.thenText;
    
    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            self.parseObjectId = object.objectId;
            self.parseUpdated = YES;
            [userActionPlans save];
        }
    }];
}

- (void)deleteFromParse {
    if (self.parseObjectId) {
        PFObject *object = [PFObject objectWithoutDataWithClassName:NSStringFromClass(self.class)
                                                           objectId:self.parseObjectId];
        [object deleteEventually];
    }
}

#pragma mark - Properties

- (NSString *)errorMessage {
    if (self.ifText.length == 0) {
        return @"Please enter your 'if' text";
    }
    else if (self.thenText.length == 0) {
        return @"Please enter your 'then' text";
    }
    return nil;
}

@end
