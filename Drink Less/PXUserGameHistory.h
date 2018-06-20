//
//  PXUserGameHistory.h
//  drinkless
//
//  Created by Edward Warrender on 11/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>
#import "PXCardGameLog.h"
#import "PXRiskGameLog.h"

@interface PXUserGameHistory : NSObject

+ (instancetype)loadGameHistory;

@property (strong, nonatomic) NSMutableArray *cardGameLogs;
@property (strong, nonatomic) NSMutableArray *riskGameLogs;

- (void)saveGameLog:(NSObject *)gameLog;

@end
