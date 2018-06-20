//
//  PXProgressToolbar.m
//  Drink Less
//
//  Created by Chris on 08/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXProgressToolbar.h"
#import "PXProgressStepsView.h"
#import "PXIntroManager.h"

static NSString *const PXTitleKey = @"title";
static NSString *const PXStageKey = @"stage";

@interface PXProgressToolbar ()

@property (strong, nonatomic) PXProgressStepsView *progressStepsView;
@property (strong, nonatomic) NSArray *stepsConfiguration;

@end

@implementation PXProgressToolbar

- (id)init {
    self = [super init];
    if (self) {
        [self initialConfiguration];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initialConfiguration];
}

- (void)initialConfiguration {
    self.stepsConfiguration = @[@{PXTitleKey: @"Privacy policy",
                                  PXStageKey: @(PXIntroStagePrivacyPolicy)},
                                @{PXTitleKey: @"Your drinking",
                                  PXStageKey: @(PXIntroStageAuditQuestions)},
                                @{PXTitleKey: @"About you",
                                  PXStageKey: @(PXIntroStageAboutYou)},
                                @{PXTitleKey: @"Compare",
                                  PXStageKey: @(PXIntroStageSlider)}];

    self.progressStepsView = [[PXProgressStepsView alloc] init];
    self.progressStepsView.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressStepsView.steps = [self.stepsConfiguration valueForKey:PXTitleKey];
    [self addSubview:self.progressStepsView];

    NSDictionary *views = NSDictionaryOfVariableBindings(_progressStepsView);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_progressStepsView]|"
                                                                 options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_progressStepsView]|"
                                                                 options:0 metrics:nil views:views]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgressBar:) name:@"PXUpdateProgressBar" object:nil];
}

- (void)updateProgressBar:(NSNotification *)notification {
    PXIntroStage introStage = [notification.object integerValue];

    __block NSInteger currentStep = 0;
    [self.stepsConfiguration enumerateObjectsUsingBlock:^(NSDictionary *dictionary, NSUInteger index, BOOL *stop) {
        NSInteger step = index + 1;

        NSInteger stage = [dictionary[PXStageKey] integerValue];
        if (introStage < stage) {
            *stop = YES;
        } else if (introStage == stage) {
            currentStep = step;
        } else if (introStage > stage) {
            currentStep = step + 1;
        }
    }];
    self.progressStepsView.currentStep = currentStep;
}

@end
