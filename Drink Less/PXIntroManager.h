//
//  PXIntroManager.h
//  drinkless
//
//  Created by Edward Warrender on 21/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PXIntroStage) {
    //PXIntroStageConsent,
    PXIntroStagePrivacyPolicy,
    PXIntroStageAuditQuestions,
    PXIntroStageAuditResults,
    PXIntroStageAboutYou,
    PXIntroStageSlider,
    PXIntroStageSliderResults,
    PXIntroStageThinkDrinkQuestion,
    PXIntroStageFinished
};

@interface PXIntroManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic) PXIntroStage stage;
@property (strong, nonatomic) NSMutableDictionary *auditAnswers;
@property (strong, nonatomic) NSMutableDictionary *demographicsAnswers;
@property (strong, nonatomic) NSMutableDictionary *estimateAnswers;
@property (strong, nonatomic) NSMutableDictionary *actualAnswers;
@property (strong, nonatomic) NSNumber *auditScore;
@property (strong, nonatomic) NSNumber *wasHelpful;
@property (nonatomic, readonly) NSNumber *gender;
@property (nonatomic, readonly) NSNumber *birthYear;
@property (nonatomic, readonly) NSNumber *age;
@property (nonatomic, getter = isParseUpdated) BOOL parseUpdated;

// Checks requirments to show the survery on suspend
@property (nonatomic, readonly) BOOL qualifiesForQuestionnaire;

- (void)save;

@end
