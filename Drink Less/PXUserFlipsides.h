//
//  PXUserFlipsides.h
//  drinkless
//
//  Created by Edward Warrender on 11/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

@class PXFlipside;

@interface PXUserFlipsides : NSObject

+ (instancetype)loadFlipsides;

@property (nonatomic, getter = hasSeenIntro) BOOL seenIntro;
@property (nonatomic, getter = hasChanges) BOOL changed;
@property (strong, nonatomic) NSArray *flipsides;
@property (strong, nonatomic) NSMutableArray *createdFlipsides;

- (void)removeFlipsideAtIndex:(NSUInteger)index;
- (void)replaceFlipsideAtIndex:(NSUInteger)index withFlipside:(PXFlipside *)flipside;
- (void)save;

@end
