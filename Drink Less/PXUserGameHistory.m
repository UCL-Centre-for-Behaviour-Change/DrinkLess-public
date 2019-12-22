//
//  PXUserGameHistory.m
//  drinkless
//
//  Created by Edward Warrender on 11/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXUserGameHistory.h"

static NSString *const PXCardGameLogsKey = @"cardGameLogs";
static NSString *const PXRiskGameLogsKey = @"riskGameLogs";

@implementation PXUserGameHistory

+ (instancetype)loadGameHistory {
    PXUserGameHistory *userGameHistory = [NSKeyedUnarchiver unarchiveObjectWithFile:[self archiveFilePath]];
    if (!userGameHistory) {
        userGameHistory = [[PXUserGameHistory alloc] init];
    }
    return userGameHistory;
}

- (id)init {
    self = [super init];
    if (self) {
        self.cardGameLogs = @[].mutableCopy;
        self.riskGameLogs = @[].mutableCopy;
    }
    return self;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.cardGameLogs = [aDecoder decodeObjectForKey:PXCardGameLogsKey];
        self.riskGameLogs = [aDecoder decodeObjectForKey:PXRiskGameLogsKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.cardGameLogs forKey:PXCardGameLogsKey];
    [aCoder encodeObject:self.riskGameLogs forKey:PXRiskGameLogsKey];
}

+ (NSString *)archiveFilePath {
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [directoryPaths.lastObject stringByAppendingPathComponent:@"userGameHistory.dat"];
}

- (void)save {
    [NSKeyedArchiver archiveRootObject:self toFile:[[self class] archiveFilePath]];
}

#pragma mark - Convenience

- (void)saveGameLog:(NSObject *)gameLog {
    if ([gameLog isKindOfClass:[PXCardGameLog class]]) {
        PXCardGameLog *cardGameLog = (PXCardGameLog *)gameLog;
        [self.cardGameLogs addObject:cardGameLog];
        [cardGameLog saveToServer];
    }
    else if ([gameLog isKindOfClass:[PXRiskGameLog class]]) {
        PXRiskGameLog *riskGameLog = (PXRiskGameLog *)gameLog;
        [self.riskGameLogs addObject:riskGameLog];
        [riskGameLog saveToParse];
    } else {
        NSLog(@"Unrecognized game log");
        return;
    }
    [self save];
}

@end
