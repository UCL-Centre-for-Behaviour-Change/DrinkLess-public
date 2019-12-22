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

//typedef NS_ENUM(NSInteger, PXGroupType) {
//    PXGroupTypeEveryone,
//    PXGroupTypeDrinkers
//};
//
//typedef NS_ENUM(NSInteger, PXPopulationType) {
//    PXPopulationTypeCountry,
//    PXPopulationTypeAgeGender
//};

typedef NS_ENUM(NSInteger, PXGraphicType) {
    PXGraphicTypeGauge,
    PXGraphicTypePeople
};

//enum GroupType;
//enum PopulationType;
//enum GenderType;

//typedef NS_ENUM(NSInteger, PXGenderType) {
//    PXGenderTypeNone,
//    PXGenderTypeMale,
//    PXGenderTypeFemale
//};
@class DemographicData;
@class AuditData;
typedef NS_ENUM(NSInteger, GroupType);
typedef NS_ENUM(NSInteger, PopulationType);


@interface PXAuditFeedbackHelper : NSObject

@property (strong, nonatomic, readonly) NSArray *percentileColors;
@property (strong, nonatomic, readonly) NSArray *percentileZones;
@property (strong, nonatomic, readonly) NSArray *percentileGaugeZones;

- (instancetype)initWithDemographicData:(DemographicData *)demographicData;

- (PXAuditFeedback *)feedbackWithAuditData:(AuditData *)auditData groupType:(GroupType)groupType populationType:(PopulationType)populationType graphicType:(PXGraphicType)graphicType;
    
- (NSDictionary *)countryEstimateZoneForAuditData:(AuditData *)auditData;
- (NSDictionary *)demographicEstimateZoneForAuditData:(AuditData *)auditData;

@end
