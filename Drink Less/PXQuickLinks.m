//
//  PXQuickLinks.m
//  drinkless
//
//  Created by Edward Warrender on 27/04/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXQuickLinks.h"
#import "PXGroupsManager.h"

@interface PXQuickLinks ()

@property (strong, nonatomic) NSMutableDictionary *allLinks;

@end

@implementation PXQuickLinks

- (id)init {
    self = [super init];
    if (self) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"QuickLinks" ofType:@"plist"];
        NSArray *plist = [NSArray arrayWithContentsOfFile:path];
        _allLinks = [NSMutableDictionary dictionaryWithCapacity:plist.count];
        
        for (NSInteger i = 0; i < plist.count; i++) {
            NSMutableDictionary *dictionary = [plist[i] mutableCopy];
            dictionary[@"index"] = @(i);
            NSString *identifier = dictionary[@"identifier"];
            _allLinks[identifier] = dictionary;
        }
    }
    return self;
}

- (NSArray *)links {
    if (!_links) {
        NSMutableArray *objects = [NSMutableArray array];
        for (NSString *identifier in self.allLinks.allKeys) {
            NSDictionary *link = self.allLinks[identifier];
            BOOL eligible = [self isEligibleForLinkWithID:identifier];
            if (eligible) {
                [objects addObject:link];
            }
        }
        _links = [objects sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]]];
    }
    return _links;
}

- (BOOL)isEligibleForLinkWithID:(NSString *)identifier {
    NSDictionary *link = self.allLinks[identifier];
    NSString *group = link[@"group"];
    if (group) {
        PXGroupsManager *groupsManager = [PXGroupsManager sharedManager];
        if ([groupsManager respondsToSelector:NSSelectorFromString(group)]) {
            if (![[groupsManager valueForKey:group] boolValue]) {
                return NO;
            }
        }
    }
    return YES;
}

- (void)reload {
    self.links = nil;
}

@end
