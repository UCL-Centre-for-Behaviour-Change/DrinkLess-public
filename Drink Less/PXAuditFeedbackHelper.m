//
//  PXAuditCalculator.m
//  drinkless
//
//  Created by Edward Warrender on 10/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXAuditFeedbackHelper.h"
#import "PXIntroManager.h"
#import "drinkless-Swift.h"

static CGFloat const PXAveragePercentile = 50.0;
static NSUInteger const PXNumberOfPeople = 20;
static NSString *const PXZoneIndex = @"zoneIndex";

@interface PXAuditFeedbackHelper ()

@property (strong, nonatomic, readonly) NSArray *lowAvFeedbackAll;
@property (strong, nonatomic, readonly) NSArray *lowAvFeedbackDrinkers;
@property (nonatomic, strong) DemographicData *demographicData;
@end

@implementation PXAuditFeedbackHelper

- (instancetype)initWithDemographicData:(DemographicData *)demographicData {
    self = [super init];
    if (self) {
        
        self.demographicData = demographicData;

        _percentileColors = @[@{PXGaugePercentile: @0, PXGaugeColor: (id)[UIColor gaugeGreenColor].CGColor}.mutableCopy,
                              @{PXGaugePercentile: @33, PXGaugeColor: (id)[UIColor gaugeYellowColor].CGColor}.mutableCopy,
                              @{PXGaugePercentile: @67, PXGaugeColor: (id)[UIColor gaugeOrangeColor].CGColor}.mutableCopy,
                              @{PXGaugePercentile: @100, PXGaugeColor: (id)[UIColor gaugeRedColor].CGColor}.mutableCopy];
        
        _percentileZones = @[@{PXZoneIndex: @0, PXGaugePercentile: @10, PXGaugeTitle: @"lowest 10%"},
                             @{PXZoneIndex: @1, PXGaugePercentile: @20, PXGaugeTitle: @"very low"},
                             @{PXZoneIndex: @2, PXGaugePercentile: @30, PXGaugeTitle: @"low"},
                             @{PXZoneIndex: @3, PXGaugePercentile: @40, PXGaugeTitle: @"low-average"},
                             @{PXZoneIndex: @4, PXGaugePercentile: @60, PXGaugeTitle: @"average (middle 20%)"},
                             @{PXZoneIndex: @5, PXGaugePercentile: @70, PXGaugeTitle: @"high-average"},
                             @{PXZoneIndex: @6, PXGaugePercentile: @80, PXGaugeTitle: @"high"},
                             @{PXZoneIndex: @7, PXGaugePercentile: @90, PXGaugeTitle: @"very-high"},
                             @{PXZoneIndex: @8, PXGaugePercentile: @100, PXGaugeTitle: @"top 10%"}];
        
        _percentileGaugeZones = @[@{PXZoneIndex: @0, PXGaugePercentile: @60, PXGaugeTitle: @"average or lower"},
                                  @{PXZoneIndex: @1, PXGaugePercentile: @70, PXGaugeTitle: @""},
                                  @{PXZoneIndex: @2, PXGaugePercentile: @80, PXGaugeTitle: @"high"},
                                  @{PXZoneIndex: @3, PXGaugePercentile: @90, PXGaugeTitle: @""},
                                  @{PXZoneIndex: @4, PXGaugePercentile: @100, PXGaugeTitle: @"top 10%"}];
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"LowAvFeedbackAll_May20" ofType:@"plist"];
        _lowAvFeedbackAll = [NSArray arrayWithContentsOfFile:path];
        path = [[NSBundle mainBundle] pathForResource:@"LowAvFeedbackDrinkers_May20" ofType:@"plist"];
        _lowAvFeedbackDrinkers = [NSArray arrayWithContentsOfFile:path];
        
    }
    return self;
}

#pragma mark - Calculations


- (NSDictionary *)calculateZoneForPercentile:(CGFloat)percentile {
    for (NSDictionary *dictionary in self.percentileZones) {
        CGFloat zonePercentile = [dictionary[PXGaugePercentile] floatValue];
        if (percentile <= zonePercentile) {
            return dictionary;
        }
    }
    return nil;
}

- (NSString *)peopleForPopulationType:(PopulationType)populationType
                            groupType:(GroupType)groupType
                          graphicType:(PXGraphicType)graphicType {
    if (populationType == PopulationTypeCountry) {
        if (groupType == GroupTypeEveryone) {
            return @"people in the UK";
        }
        else {
            return @"drinkers in the UK";
        }
    } else {
        
        NSString *genderStr = self.demographicData.gender == GenderTypeMale ? @"men" : @"women";
        
        if (graphicType == PXGraphicTypePeople && populationType == PopulationTypeDemographic) {
            
            if (groupType == GroupTypeEveryone) {
                return [NSString stringWithFormat:@"%@ aged %@", genderStr, self.demographicData.ageGroup];
            }
            else {
                return [NSString stringWithFormat:@"%@ aged %@ who drink,", genderStr, self.demographicData.ageGroup];
            }
        }
        else if (groupType == GroupTypeEveryone) {
            return [NSString stringWithFormat:@"%@ aged %@", genderStr, self.demographicData.ageGroup];
        }
        else {
            return [NSString stringWithFormat:@"%@ who drink aged %@", genderStr, self.demographicData.ageGroup];
        }
        
    }
}

- (NSString *)accuracyForAuditData:(AuditData *)auditData populationType:(PopulationType)populationType resultZone:(NSDictionary *)resultZone {
    NSDictionary *estimateZone;
    if (populationType == PopulationTypeCountry) {
        estimateZone = [self countryEstimateZoneForAuditData:auditData];
    } else {
        estimateZone = [self demographicEstimateZoneForAuditData:auditData];
    }
    NSInteger estimateIndex = [estimateZone[PXZoneIndex] integerValue];
    NSInteger resultIndex = [resultZone[PXZoneIndex] integerValue];
    
    if (estimateIndex > resultIndex) {
        return @"over-";
    } else if (estimateIndex < resultIndex) {
        return @"under-";
    } else {
        return @"correctly ";
    }
}

- (NSString *)textForPeopleCount:(NSNumber *)peopleCount {
    if (peopleCount.unsignedIntegerValue == PXNumberOfPeople) {
        return @"all";
    } else {
        return peopleCount.stringValue;
    }
}

- (CGFloat)lowAvFeedbackPercentileForPopulationType:(PopulationType)populationType groupType:(GroupType)groupType {
    NSString *key = [self.demographicData keyFor:populationType]; 
    
    NSArray *feedbackDataArr = groupType == GroupTypeDrinkers ? self.lowAvFeedbackDrinkers : self.lowAvFeedbackAll;
    NSNumber *percentile = feedbackDataArr.firstObject[key];
    return percentile.floatValue;
}

- (PXAuditFeedback *)feedbackWithAuditData:(AuditData *)auditData groupType:(GroupType)groupType populationType:(PopulationType)populationType graphicType:(PXGraphicType)graphicType {
    
    NSString *text;
    double estimate = [auditData estimatePercentileFor:populationType];
    double percentile = [auditData actualPercentileWithGroupType:groupType populationType:populationType];
    
    if (graphicType == PXGraphicTypePeople) {
        NSString *people = [self peopleForPopulationType:populationType
                                               groupType:groupType
                                             graphicType:graphicType];
//        NSString *alcoholRelated = groupType == GroupTypeEveryone ? @"alcohol-related " : @"";
        if (percentile <= PXAveragePercentile) {
            percentile = [self lowAvFeedbackPercentileForPopulationType:populationType groupType:groupType];
            NSNumber *peopleCount = @(roundf(PXNumberOfPeople * (percentile / 100.0)));
            text = [NSString stringWithFormat:@"%@ out of %lu %@ drink alcohol once a week or less.", peopleCount.stringValue, (long unsigned)PXNumberOfPeople, people];
        } else {
            NSNumber *peopleCount = @(roundf(PXNumberOfPeople * (percentile / 100.0)));
            NSString *textForPeopleCount = [self textForPeopleCount:peopleCount];
            text = [NSString stringWithFormat:@"This means for every %lu %@ you drink more than %@ of them.", (long unsigned)PXNumberOfPeople, people, /*alcoholRelated,*/ textForPeopleCount];
//            text = [NSString stringWithFormat:@"This means for every %lu %@, you’re at a greater %@risk than %@ of them.", (long unsigned)PXNumberOfPeople, people, alcoholRelated, textForPeopleCount];
        }
    } else {
        NSDictionary *resultZone = [self calculateZoneForPercentile:percentile];
        NSString *accuracy = [self accuracyForAuditData:auditData populationType:populationType resultZone:resultZone];
        NSString *people = [self peopleForPopulationType:populationType
                                               groupType:groupType
                                             graphicType:graphicType];
        if (percentile <= PXAveragePercentile) {
            text = [NSString stringWithFormat:@"Your drinking is average or less than average compared with other %@.\n\nYou %@estimated how much you drink compared to other %@.", people, accuracy, people];
        } else {
            text = [NSString stringWithFormat:@"Your drinking is greater than %.f%% of other %@.\n\nYou %@estimated how much you drink compared with other %@.", percentile, people, accuracy, people];
        }
    }
    PXAuditFeedback *feedback = [[PXAuditFeedback alloc] initWithEstimate:estimate percentile:percentile text:text];
    return feedback;
}

- (NSDictionary *)countryEstimateZoneForAuditData:(AuditData *)auditData {
    return [self calculateZoneForPercentile:auditData.countryEstimate];
}

- (NSDictionary *)demographicEstimateZoneForAuditData:(AuditData *)auditData {
    return [self calculateZoneForPercentile:auditData.demographicEstimate];
}



@end
