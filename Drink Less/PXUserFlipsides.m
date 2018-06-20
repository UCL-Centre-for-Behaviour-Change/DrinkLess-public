//
//  PXUserFlipsides.m
//  drinkless
//
//  Created by Edward Warrender on 11/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXUserFlipsides.h"
#import "PXFlipside.h"

static NSString *const PXSeenIntroKey = @"seenIntro";
static NSString *const PXCreatedFlipsidesKey = @"createdFlipsides";

@interface PXUserFlipsides () <NSCoding>

@property (strong, nonatomic) NSMutableArray *exampleFlipsides;

@end

@implementation PXUserFlipsides

+ (instancetype)loadFlipsides {
    PXUserFlipsides *userFlipsides = [NSKeyedUnarchiver unarchiveObjectWithFile:[self archiveFilePath]];
    if (!userFlipsides) {
        userFlipsides = [[PXUserFlipsides alloc] init];
    }
    return userFlipsides;
}

- (id)init {
    self = [super init];
    if (self) {
        self.seenIntro = NO;
        self.createdFlipsides = @[].mutableCopy;
    }
    return self;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.seenIntro = [aDecoder decodeBoolForKey:PXSeenIntroKey];
        self.createdFlipsides = [[aDecoder decodeObjectForKey:PXCreatedFlipsidesKey] mutableCopy];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBool:self.hasSeenIntro forKey:PXSeenIntroKey];
    [aCoder encodeObject:self.createdFlipsides forKey:PXCreatedFlipsidesKey];
}

+ (NSString *)archiveFilePath {
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [directoryPaths.lastObject stringByAppendingPathComponent:@"userFlipsides.dat"];
}

- (void)removeFlipsideAtIndex:(NSUInteger)index {
    PXFlipside *flipside = self.createdFlipsides[index];
    flipside.positiveImageID = nil;
    flipside.negativeImageID = nil;
    [self.createdFlipsides removeObjectAtIndex:index];
    self.changed = YES;
}

- (void)replaceFlipsideAtIndex:(NSUInteger)index withFlipside:(PXFlipside *)flipside {
    [self removeFlipsideAtIndex:index];
    [self.createdFlipsides insertObject:flipside atIndex:index];
}

- (void)save {
    [NSKeyedArchiver archiveRootObject:self toFile:[[self class] archiveFilePath]];
}

#pragma mark - Properties

- (NSMutableArray *)exampleFlipsides {
    if (!_exampleFlipsides) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Flipsides" ofType:@"plist"];
        NSArray *plist = [NSArray arrayWithContentsOfFile:path];
        
        _exampleFlipsides = [[NSMutableArray alloc] initWithCapacity:plist.count];
        for (NSInteger i = 0; i < plist.count; i++) {
            NSDictionary *dictionary = plist[i];
            PXFlipside *flipside = [[PXFlipside alloc] init];
            flipside.positiveText = dictionary[@"positive"];
            flipside.negativeText = dictionary[@"negative"];
            NSString *imageNameFormat = @"flipside-%lu-%@";
            NSString *positiveImageName = [NSString stringWithFormat:imageNameFormat, (long)i, @"positive"];
            NSString *negativeImageName = [NSString stringWithFormat:imageNameFormat, (long)i, @"negative"];
            flipside.positiveImage = [UIImage imageNamed:positiveImageName];
            flipside.negativeImage = [UIImage imageNamed:negativeImageName];
            [_exampleFlipsides addObject:flipside];
        }
    }
    return _exampleFlipsides;
}

- (NSArray *)flipsides {
    if (!_flipsides) {
        NSMutableArray *array = [NSMutableArray arrayWithArray:self.exampleFlipsides];
        [array addObjectsFromArray:self.createdFlipsides];
        _flipsides = array.copy;
    }
    return _flipsides;
}

@end
