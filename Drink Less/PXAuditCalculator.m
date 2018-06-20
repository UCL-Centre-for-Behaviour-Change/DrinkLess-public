//
//  PXAuditCalculator.m
//  drinkless
//
//  Created by Edward Warrender on 10/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXAuditCalculator.h"
#import "PXIntroManager.h"

static CGFloat const PXAveragePercentile = 50.0;
static NSUInteger const PXNumberOfPeople = 20;
static NSString *const PXZoneIndex = @"zoneIndex";

@interface PXAuditCalculator ()

@property (strong, nonatomic, readonly) NSArray *lowAvFeedback;
@property (strong, nonatomic, readonly) NSArray *groupAll;
@property (strong, nonatomic, readonly) NSArray *groupDrinkers;
@property (nonatomic, readonly) NSInteger age;

@end

@implementation PXAuditCalculator

- (instancetype)init {
    self = [super init];
    if (self) {
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
        
        NSString *lowAvFeedbackPath = [[NSBundle mainBundle] pathForResource:@"LowAvFeedback" ofType:@"plist"];
        _lowAvFeedback = [NSArray arrayWithContentsOfFile:lowAvFeedbackPath];
        
        NSString *groupAllPath = [[NSBundle mainBundle] pathForResource:@"AuditGroupAll" ofType:@"plist"];
        _groupAll = [NSArray arrayWithContentsOfFile:groupAllPath];
        
        NSString *groupDrinkersPath = [[NSBundle mainBundle] pathForResource:@"AuditGroupDrinkers" ofType:@"plist"];
        _groupDrinkers = [NSArray arrayWithContentsOfFile:groupDrinkersPath];
        
        PXIntroManager *introManager = [PXIntroManager sharedManager];
        _age = introManager.age.integerValue;
        
        BOOL isFemale = [PXIntroManager sharedManager].gender.boolValue;
        _genderType = isFemale ? PXGenderTypeFemale : PXGenderTypeMale;
        _gender = _genderType == PXGenderTypeMale ? @"men" : @"women";
        [self calculateDemographic];
        
        self.countryEstimate = introManager.estimateAnswers[@"all-UK:estimate"];
        self.demographicEstimate = introManager.estimateAnswers[[NSString stringWithFormat:@"%@:estimate",_demographicKey]];
    }
    return self;
}

#pragma mark - Calculations

- (void)calculateDemographic {
    NSString *gender = self.genderType == PXGenderTypeMale ? @":male" : @":female";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS %@", gender];
    
    NSArray *keys = [[self.groupAll.firstObject allKeys] filteredArrayUsingPredicate:predicate];
    keys = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    
    for (NSUInteger i = 0; i < keys.count; i++) {
        NSString *key = keys[i];
        NSArray *components = [key componentsSeparatedByString:@":"];
        NSString *ageGroup = components.firstObject;
        NSArray *ageComponents = [ageGroup componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-+"]];
        NSInteger lower = [ageComponents.firstObject integerValue];
        NSInteger upper = [ageComponents.lastObject integerValue];
        
        BOOL lowerThanFirstBoundary = (i == 0 && self.age < lower);
        BOOL withinBoundaryRange = (self.age >= lower && (upper == 0 || self.age <= upper));
        if (lowerThanFirstBoundary || withinBoundaryRange) {
            _demographicKey = key;
            _ageGroup = ageGroup;
            break;
        }
    }
}

- (NSDictionary *)calculateZoneForPercentile:(CGFloat)percentile {
    for (NSDictionary *dictionary in self.percentileZones) {
        CGFloat zonePercentile = [dictionary[PXGaugePercentile] floatValue];
        if (percentile <= zonePercentile) {
            return dictionary;
        }
    }
    return nil;
}

- (NSNumber *)estimateForPopulationType:(PXPopulationType)populationType {
    if (populationType == PXPopulationTypeCountry) {
        return self.countryEstimate;
    } else {
        return self.demographicEstimate;
    }
}

- (NSString *)peopleForPopulationType:(PXPopulationType)populationType
                            groupType:(PXGroupType)groupType
                          graphicType:(PXGraphicType)graphicType {
    if (populationType == PXPopulationTypeCountry) {
        if (groupType == PXGroupTypeEveryone) {
            return @"people in the UK";
        }
        else {
            return @"drinkers in the UK";
        }
    } else {
        if (graphicType == PXGraphicTypePeople && populationType == PXPopulationTypeAgeGender) {
            
            if (groupType == PXGroupTypeEveryone) {
                return [NSString stringWithFormat:@"%@ aged %@", self.gender, self.ageGroup];
            }
            else {
                return [NSString stringWithFormat:@"%@ aged %@ who drink", self.gender, self.ageGroup];
            }
        }
        else if (groupType == PXGroupTypeEveryone) {
            return [NSString stringWithFormat:@"%@ who aged %@", self.gender, self.ageGroup];
        }
        else {
            return [NSString stringWithFormat:@"%@ who drink aged %@", self.gender, self.ageGroup];
        }
        
    }
}

- (NSString *)accuracyForPopulationType:(PXPopulationType)populationType resultZone:(NSDictionary *)resultZone {
    NSDictionary *estimateZone;
    if (populationType == PXPopulationTypeCountry) {
        estimateZone = self.countryEstimateZone;
    } else {
        estimateZone = self.demographicEstimateZone;
    }
    NSInteger estimateIndex = [estimateZone[PXZoneIndex] integerValue];
    NSInteger resultIndex = [resultZone[PXZoneIndex] integerValue];
    
    if (estimateIndex > resultIndex) {
        return @"under";
    } else if (estimateIndex < resultIndex) {
        return @"over";
    } else {
        return @"correctly";
    }
}

- (NSString *)textForPeopleCount:(NSNumber *)peopleCount {
    if (peopleCount.unsignedIntegerValue == PXNumberOfPeople) {
        return @"all";
    } else {
        return peopleCount.stringValue;
    }
}

- (NSString *)keyForPopulationType:(PXPopulationType)populationType {
    return populationType == PXPopulationTypeCountry ? @"all-UK" : self.demographicKey;
}

- (CGFloat)percentileForScore:(NSNumber *)score groupType:(PXGroupType)groupType populationType:(PXPopulationType)populationType cutOffBelowAverage:(BOOL)cutOffBelowAverage {
    NSArray *group = groupType == PXGroupTypeEveryone ? self.groupAll : self.groupDrinkers;
    NSString *key = [self keyForPopulationType:populationType];
    
    NSPredicate *equalPredicate = [NSPredicate predicateWithFormat:@"%K == %@", key, score];
    NSDictionary *equalScore = [group filteredArrayUsingPredicate:equalPredicate].lastObject;
    if (equalScore) {
        return [equalScore[PXGaugePercentile] floatValue];
    }
    NSPredicate *lowestPredicate = [NSPredicate predicateWithFormat:@"%K < %@", key, score];
    NSDictionary *lowestNeighbour = [group filteredArrayUsingPredicate:lowestPredicate].lastObject;
    
    NSPredicate *highestPredicate = [NSPredicate predicateWithFormat:@"%K > %@", key, score];
    NSDictionary *highestNeighbour = [group filteredArrayUsingPredicate:highestPredicate].firstObject;
    
    if (cutOffBelowAverage && !lowestNeighbour) {
        // Don't interpolate if the score was lower than the lowest percentile boundary
        // The user's drinking is shown as average or lower so they don't drink more
        return [highestNeighbour[PXGaugePercentile] floatValue];
    }
    
    CGFloat lowerScore = [lowestNeighbour[key] floatValue];
    CGFloat lowerPercentile = [lowestNeighbour[PXGaugePercentile] floatValue];
    CGFloat upperScore = [highestNeighbour[key] floatValue];
    CGFloat upperPercentile = [highestNeighbour[PXGaugePercentile] floatValue];
    CGFloat scoreDifferenceDecimal = (score.floatValue - lowerScore) / (upperScore - lowerScore);
    return lowerPercentile + ((upperPercentile - lowerPercentile) * scoreDifferenceDecimal);
}

- (CGFloat)lowAvFeedbackPercentileForPopulationType:(PXPopulationType)populationType {
    NSString *key = [self keyForPopulationType:populationType];
    NSNumber *percentile = self.lowAvFeedback.firstObject[key];
    return percentile.floatValue;
}

- (PXAuditFeedback *)feedbackWithGroupType:(PXGroupType)groupType populationType:(PXPopulationType)populationType graphicType:(PXGraphicType)graphicType {
    NSString *text;
    double estimate = [self estimateForPopulationType:populationType].floatValue;
    PXIntroManager *introManager = [PXIntroManager sharedManager];
    double percentile = [self percentileForScore:introManager.auditScore groupType:groupType populationType:populationType cutOffBelowAverage:YES];
    
    if (graphicType == PXGraphicTypePeople) {
        NSString *people = [self peopleForPopulationType:populationType
                                               groupType:groupType
                                             graphicType:graphicType];
        NSString *alcoholRelated = groupType == PXGroupTypeEveryone ? @"alcohol-related " : @"";
        if (percentile <= PXAveragePercentile) {
            percentile = [self lowAvFeedbackPercentileForPopulationType:populationType];
            NSNumber *peopleCount = @(roundf(PXNumberOfPeople * (percentile / 100.0)));
            text = [NSString stringWithFormat:@"%@ out of %lu %@ drink alcohol once a week or less.", peopleCount.stringValue, (long unsigned)PXNumberOfPeople, people];
        } else {
            NSNumber *peopleCount = @(roundf(PXNumberOfPeople * (percentile / 100.0)));
            NSString *textForPeopleCount = [self textForPeopleCount:peopleCount];
            text = [NSString stringWithFormat:@"This means for every %lu %@ you’re at a greater %@risk than %@ of them.", (long unsigned)PXNumberOfPeople, people, alcoholRelated, textForPeopleCount];
        }
    } else {
        NSDictionary *resultZone = [self calculateZoneForPercentile:percentile];
        NSString *accuracy = [self accuracyForPopulationType:populationType resultZone:resultZone];
        NSString *people = [self peopleForPopulationType:populationType
                                               groupType:groupType
                                             graphicType:graphicType];
        NSString *drink = groupType == PXGroupTypeEveryone ? @"drink" : @"consume";
        if (percentile <= PXAveragePercentile) {
            text = [NSString stringWithFormat:@"Your drinking is average or lower than other %@.\n\nYou %@-estimated how much other %@ %@", people, accuracy, people, drink];
        } else {
            text = [NSString stringWithFormat:@"Your drinking is greater than %.f%% of other %@.\n\nYou %@-estimated how much other %@ %@.", percentile, people, accuracy, people, drink];
        }
    }
    PXAuditFeedback *feedback = [[PXAuditFeedback alloc] initWithEstimate:estimate percentile:percentile text:text];
    return feedback;
}

#pragma mark - Properties

- (void)setCountryEstimate:(NSNumber *)countryEstimate {
    _countryEstimate = countryEstimate;
    self.countryEstimateZone = [self calculateZoneForPercentile:countryEstimate.floatValue];
}

- (void)setDemographicEstimate:(NSNumber *)demographicEstimate {
    _demographicEstimate = demographicEstimate;
    self.demographicEstimateZone = [self calculateZoneForPercentile:demographicEstimate.floatValue];
}

- (NSMutableDictionary *)estimateAnswers {
    
    NSString *demographicKey = [NSString stringWithFormat:@"%@:estimate", self.demographicKey];
    return @{@"all-UK:estimate": self.countryEstimate, demographicKey : self.demographicEstimate}.mutableCopy;
}

@end
