//
//  PXUserIdentity.h
//  drinkless
//
//  Created by Edward Warrender on 04/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

@interface PXUserIdentity : NSObject <NSCoding>

+ (instancetype)loadUserIdentity;

@property (nonatomic, getter = hasSeenIntro) BOOL seenIntro;
@property (strong, nonatomic) UIImage *photo;
@property (strong, nonatomic) NSString *photoID;
@property (strong, nonatomic) NSArray *createdAspects;
@property (strong, nonatomic) NSMutableArray *importantAspects;
@property (strong, nonatomic) NSMutableSet *contradictedAspects;
@property (strong, nonatomic) NSArray *exampleContradictions;

- (void)save;

@end
