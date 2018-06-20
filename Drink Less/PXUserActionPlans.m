//
//  PXUserActionPlans.m
//  drinkless
//
//  Created by Edward Warrender on 16/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXUserActionPlans.h"

static NSString *const PXActionPlansKey = @"actionPlans";

@implementation PXUserActionPlans

+ (instancetype)loadActionPlans {
    PXUserActionPlans *userActionPlans = [NSKeyedUnarchiver unarchiveObjectWithFile:[self archiveFilePath]];
    if (!userActionPlans) {
        userActionPlans = [[PXUserActionPlans alloc] init];
    }
    return userActionPlans;
}

- (id)init {
    self = [super init];
    if (self) {
        self.actionPlans = @[].mutableCopy;
    }
    return self;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.actionPlans = [[aDecoder decodeObjectForKey:PXActionPlansKey] mutableCopy];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.actionPlans forKey:PXActionPlansKey];
}

+ (NSString *)archiveFilePath {
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [directoryPaths.lastObject stringByAppendingPathComponent:@"userActionPlans.dat"];
}

- (void)save {
    [NSKeyedArchiver archiveRootObject:self toFile:[[self class] archiveFilePath]];
}

@end
