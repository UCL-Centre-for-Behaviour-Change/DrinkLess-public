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
    PXIntroStageFinished,
    PXIntroStageCreateGoal  // added later MUSTN'T move the Finished enum as its int value is stored in NSUserDefs

};

@interface PXIntroManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic) PXIntroStage stage;
//@property (strong, nonatomic) NSMutableDictionary *demographicsAnswers; // @deprecated
@property (strong, nonatomic) NSNumber *wasHelpful;
@property (nonatomic, getter = isParseUpdated) BOOL parseUpdated;


// Checks requirments to show the survery on suspend
//@property (nonatomic, readonly) BOOL qualifiesForQuestionnaire;

- (void)save;

@end
