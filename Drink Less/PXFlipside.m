//
//  PXFlipside.m
//  drinkless
//
//  Created by Edward Warrender on 12/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXFlipside.h"
#import "PXImageStore.h"

static NSString *const PXPositiveTextKey = @"positiveText";
static NSString *const PXNegativeTextKey = @"negativeText";
static NSString *const PXPositiveImageIDKey = @"positiveImageID";
static NSString *const PXNegativeImageIDKey = @"negativeImageID";

@implementation PXFlipside

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.positiveText = [aDecoder decodeObjectForKey:PXPositiveTextKey];
        self.negativeText = [aDecoder decodeObjectForKey:PXNegativeTextKey];
        self.positiveImageID = [aDecoder decodeObjectForKey:PXPositiveImageIDKey];
        self.negativeImageID = [aDecoder decodeObjectForKey:PXNegativeImageIDKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.positiveText forKey:PXPositiveTextKey];
    [aCoder encodeObject:self.negativeText forKey:PXNegativeTextKey];
    [aCoder encodeObject:self.positiveImageID forKey:PXPositiveImageIDKey];
    [aCoder encodeObject:self.negativeImageID forKey:PXNegativeImageIDKey];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    PXFlipside *flipside = [[self class] allocWithZone:zone];
    flipside.positiveText = self.positiveText.copy;
    flipside.negativeText = self.negativeText.copy;
    if (self.positiveImage) {
        flipside.positiveImageID = [[PXImageStore sharedImageStore] addImage:self.positiveImage.copy];
    }
    if (self.negativeImage) {
        flipside.negativeImageID = [[PXImageStore sharedImageStore] addImage:self.negativeImage.copy];
    }
    return flipside;
}

#pragma mark - Properties

- (NSString *)errorMessage {
    if (self.negativeText.length == 0) {
        return @"Please enter the negative text";
    }
    else if (self.positiveText.length == 0) {
        return @"Please enter the positive text";
    }
    return nil;
}

- (UIImage *)positiveImage {
    if (!_positiveImage) {
        if (self.positiveImageID) {
            _positiveImage = [[PXImageStore sharedImageStore] imageForKey:self.positiveImageID];
        }
    }
    return _positiveImage;
}

- (UIImage *)negativeImage {
    if (!_negativeImage) {
        if (self.negativeImageID) {
            _negativeImage = [[PXImageStore sharedImageStore] imageForKey:self.negativeImageID];
        }
    }
    return _negativeImage;
}

- (void)setPositiveImageID:(NSString *)positiveImageID {
    if (_positiveImageID) {
        [[PXImageStore sharedImageStore] removeImageForKey:_positiveImageID];
    }
    _positiveImageID = positiveImageID;
}

- (void)setNegativeImageID:(NSString *)negativeImageID {
    if (_negativeImageID) {
        [[PXImageStore sharedImageStore] removeImageForKey:_negativeImageID];
    }
    _negativeImageID = negativeImageID;
}

@end
