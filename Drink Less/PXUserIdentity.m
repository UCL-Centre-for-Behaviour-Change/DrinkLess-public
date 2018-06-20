//
//  PXUserIdentity.m
//  drinkless
//
//  Created by Edward Warrender on 04/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXUserIdentity.h"
#import "PXImageStore.h"

static NSString *const PXSeenIntroKey = @"seenIntro";
static NSString *const PXPhotoIDKey = @"photoID";
static NSString *const PXCreatedAspectsKey = @"createdAspects";
static NSString *const PXImportantAspects = @"importantAspects";
static NSString *const PXContradictedAspects = @"contradictedAspects";

@implementation PXUserIdentity

+ (instancetype)loadUserIdentity {
    PXUserIdentity *userIdentity = [NSKeyedUnarchiver unarchiveObjectWithFile:[self archiveFilePath]];
    if (!userIdentity) {
        userIdentity = [[PXUserIdentity alloc] init];
    }
    return userIdentity;
}

- (id)init {
    self = [super init];
    if (self) {
        self.seenIntro = NO;
        self.createdAspects = @[].mutableCopy;
        self.importantAspects = @[].mutableCopy;
        self.contradictedAspects = @[].mutableCopy;
    }
    return self;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.seenIntro = [aDecoder decodeBoolForKey:PXSeenIntroKey];
        self.photoID = [aDecoder decodeObjectForKey:PXPhotoIDKey];
        self.createdAspects = [aDecoder decodeObjectForKey:PXCreatedAspectsKey];
        self.importantAspects = [aDecoder decodeObjectForKey:PXImportantAspects];
        self.contradictedAspects = [aDecoder decodeObjectForKey:PXContradictedAspects];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBool:self.hasSeenIntro forKey:PXSeenIntroKey];
    [aCoder encodeObject:self.photoID forKey:PXPhotoIDKey];
    [aCoder encodeObject:self.createdAspects forKey:PXCreatedAspectsKey];
    [aCoder encodeObject:self.importantAspects forKey:PXImportantAspects];
    [aCoder encodeObject:self.contradictedAspects forKey:PXContradictedAspects];
}

+ (NSString *)archiveFilePath {
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [directoryPaths.lastObject stringByAppendingPathComponent:@"userIdentity.dat"];
}

- (void)save {
    [NSKeyedArchiver archiveRootObject:self toFile:[[self class] archiveFilePath]];
}

#pragma mark - Properties

- (NSArray *)exampleContradictions {
    if (!_exampleContradictions) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Contradictions" ofType:@"plist"];
        _exampleContradictions = [NSArray arrayWithContentsOfFile:path];
    }
    return _exampleContradictions;
}

- (UIImage *)photo {
    if (!_photo) {
        if (self.photoID) {
            _photo = [[PXImageStore sharedImageStore] imageForKey:self.photoID];
        }
    }
    return _photo;
}

- (void)setPhotoID:(NSString *)photoID {
    if (_photoID) {
        [[PXImageStore sharedImageStore] removeImageForKey:_photoID];
    }
    _photoID = photoID;
}

@end
