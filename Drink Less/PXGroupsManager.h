//
//  PXGroups.h
//  drinkless
//
//  Created by Edward Warrender on 18/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

@interface PXGroupsManager : NSObject

+ (instancetype)sharedManager;

//- (void)saveToParse;

@property (strong, nonatomic) NSNumber *groupID;
@property (strong, nonatomic) NSNumber *highAP;
@property (strong, nonatomic) NSNumber *highID;
@property (strong, nonatomic) NSNumber *highAAT;
@property (strong, nonatomic) NSNumber *highNM;
@property (strong, nonatomic) NSNumber *highSM;

@end
