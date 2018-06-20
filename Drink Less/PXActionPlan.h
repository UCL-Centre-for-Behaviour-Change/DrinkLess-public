//
//  PXActionPlan.h
//  drinkless
//
//  Created by Edward Warrender on 16/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Parse/Parse.h>

@class PXUserActionPlans;

@interface PXActionPlan : NSObject <NSCopying, NSCoding>

@property (strong, nonatomic) NSString *ifText;
@property (strong, nonatomic) NSString *thenText;
@property (strong, nonatomic) NSString *parseObjectId;
@property (nonatomic, getter = isParseUpdated) BOOL parseUpdated;
@property (nonatomic, readonly) NSString *errorMessage;

- (void)saveAndLogToParse:(PXUserActionPlans *)userActionPlans;
- (void)deleteFromParse;

@end
