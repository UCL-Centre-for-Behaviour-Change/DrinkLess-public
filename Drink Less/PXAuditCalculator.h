//
//  PXAuditCalculator.h
//  drinkless
//
//  Created by Edward Warrender on 10/12/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>
#import "PXAuditFeedback.h"

static NSString *const PXGaugePercentile = @"percentile";
static NSString *const PXGaugeColor = @"color";
static NSString *const PXGaugeTitle = @"title";

typedef NS_ENUM(NSInteger, PXGroupType) {
    PXGroupTypeEveryone,
    PXGroupTypeDrinkers
};

typedef NS_ENUM(NSInteger, PXPopulationType) {
    PXPopulationTypeCountry,
    PXPopulationTypeAgeGender
};

typedef NS_ENUM(NSInteger, PXGraphicType) {
    PXGraphicTypeGauge,
    PXGraphicTypePeople
};

typedef NS_ENUM(NSInteger, PXGenderType) {
    PXGenderTypeNone,
    PXGenderTypeMale,
    PXGenderTypeFemale
};

@interface PXAuditCalculator : NSObject

@property (strong, nonatomic, readonly) NSArray *percentileColors;
@property (strong, nonatomic, readonly) NSArray *percentileZones;
@property (strong, nonatomic, readonly) NSArray *percentileGaugeZones;
@property (strong, nonatomic, readonly) NSString *gender;
@property (nonatomic, readonly) PXGenderType genderType;
@property (strong, nonatomic, readonly) NSString *ageGroup;
@property (strong, nonatomic, readonly) NSMutableDictionary *estimateAnswers;
@property (strong, nonatomic) NSNumber *countryEstimate;
@property (strong, nonatomic) NSDictionary *countryEstimateZone;
@property (strong, nonatomic) NSNumber *demographicEstimate;
@property (strong, nonatomic) NSDictionary *demographicEstimateZone;
@property (strong, nonatomic, readonly) NSString *demographicKey;

- (PXAuditFeedback *)feedbackWithGroupType:(PXGroupType)groupType populationType:(PXPopulationType)populationType graphicType:(PXGraphicType)graphicType;
- (CGFloat)percentileForScore:(NSNumber *)score groupType:(PXGroupType)groupType populationType:(PXPopulationType)populationType cutOffBelowAverage:(BOOL)cutOffBelowAverage;

@end
