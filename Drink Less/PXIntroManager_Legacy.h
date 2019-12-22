//
//  PXIntroManager_Legacy.h
//  drinkless
//
//  Created by Hari Karam Singh on 15/10/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

#import "PXIntroManager.h"

NS_ASSUME_NONNULL_BEGIN


@interface PXIntroManager ()

@property (strong, nonatomic) NSMutableDictionary *auditAnswers;
@property (strong, nonatomic) NSMutableDictionary *demographicsAnswers;
@property (strong, nonatomic) NSMutableDictionary *estimateAnswers;
@property (strong, nonatomic) NSMutableDictionary *actualAnswers;
@property (strong, nonatomic) NSNumber *auditScore;

@end

NS_ASSUME_NONNULL_END
