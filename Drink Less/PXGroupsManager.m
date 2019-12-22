//
//  PXGroups.m
//  drinkless
//
//  Created by Edward Warrender on 18/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXGroupsManager.h"
#import <Parse/Parse.h>

static NSString *const PXGroupIDKey = @"groupID";

@interface PXGroupsManager ()

@property (strong, nonatomic) NSMutableDictionary *groups;

@end

@implementation PXGroupsManager

@synthesize groupID = _groupID;

+ (instancetype)sharedManager {
    static PXGroupsManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (id)init {
    self = [super init];
    if (self) {
//        NSInteger randomId = arc4random_uniform((u_int32_t)self.groups.count) + 1;
//        self.groupID = @(randomId);
        // New way is to default to 0 (no group) and get bucket via Parse if user meets certain criteria: https://github.com/PortablePixels/DrinkLess/issues/183
        // This was in the getter but it would seemingly never be called as the groupID is set in the init. It's backing it to parse anyway so is this still valid?
        NSNumber *gid = [[NSUserDefaults standardUserDefaults] objectForKey:PXGroupIDKey];
        if (gid) {
            _groupID = gid;
        } else {
            self.groupID = @0;
        }
        
        [self updateGroupValues];
        
//        PFUser *currentUser = [PFUser currentUser];
//        if (!currentUser[PXGroupIDKey]) {
//            [self saveToParse];
//        }
    }
    return self;
}

- (NSNumber *)groupID {
    return _groupID;
}

- (void)updateGroupValues {
    
    NSDictionary *group = self.groups[self.groupID];
    for (NSString *key in group.allKeys) {
        NSNumber *number = group[key];
        SEL selector = NSSelectorFromString(key);
        if ([self respondsToSelector:selector]) {
            [self setValue:number forKey:key];
        }
    }
}

- (void)setGroupID:(NSNumber *)groupID {
    _groupID = groupID;
    [[NSUserDefaults standardUserDefaults] setObject:groupID forKey:PXGroupIDKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self updateGroupValues];
//    [self saveToParse];
}

//- (void)saveToParse {
//    PFUser *currentUser = [PFUser currentUser];
//    currentUser[PXGroupIDKey] = self.groupID;
//    NSLog(@"[PARSE]: Saving groupID %@ to user: %@", self.groupID, currentUser);
//    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//        NSLog(@"[PARSE]: Save groupID result: groupId=%@ success? %@, Error: %@ ", self.groupID, succeeded?@"YES":@"NO", error);
//    }];
//}

- (NSMutableDictionary *)groups {
    if (_groups) {
        return _groups;
    }
    NSInteger groupID = 1;
    _groups = [NSMutableDictionary dictionary];
    for (NSInteger AP = 0; AP < 2; AP++) {
        for (NSInteger ID = 0; ID < 2; ID++) {
            for (NSInteger AAT = 0; AAT < 2; AAT++) {
                for (NSInteger NM = 0; NM < 2; NM++) {
                    for (NSInteger SM = 0; SM < 2; SM++) {
                        NSDictionary *dictionary = @{@"highAP": @(AP), @"highID": @(ID), @"highAAT": @(AAT), @"highNM": @(NM), @"highSM": @(SM)};
                        _groups[@(groupID)] = dictionary;
//                        NSLog(@"Dictionary %@", dictionary) ;
//                        NSLog(@"groupID: %ld", (long)groupID) ;
                        groupID++;
                    }
                }
            }
        }
    }
    
    // Special group 0 means outside of the groups and everything turned on
    _groups[@0] = @{@"highAP": @1, @"highID": @1, @"highAAT": @1, @"highNM": @1, @"highSM": @1};
    
    return _groups;
}


@end
