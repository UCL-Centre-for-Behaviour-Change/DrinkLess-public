//
//  PXPeopleView.m
//  drinkless
//
//  Created by Edward Warrender on 24/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXPeopleView.h"
#import "drinkless-Swift.h"
#import "PXAuditFeedbackHelper.h"

static NSString *const PXSolidView = @"solidView";
static NSString *const PXGradientView = @"gradientView";

static CGFloat const PXHeight = 160.0;
static NSUInteger const PXHorizontalInset = 15.0;
static NSUInteger const PXHorizontalPadding = 2.0;
static NSUInteger const PXVerticalPadding = 10.0;
static NSUInteger const PXRows = 2;
static NSUInteger const PXNumberOfPeople = 20;

@interface PXPeopleView ()

@property (strong, nonatomic) NSMutableArray *rowViews;
@property (strong, nonatomic) NSMutableArray *rowGradientLayers;

@end

@implementation PXPeopleView

- (void)initialConfiguration {
    [super initialConfiguration];
    
    self.contentView.frame = CGRectMake(0.0, 0.0, PXWidth, PXHeight);
    self.backgroundImageView.image = [UIImage imageNamed:@"people-bg"];
    
    CGFloat gradientHeight = (PXHeight - (PXVerticalPadding * PXRows)) / PXRows;
    CGFloat rowWidth = PXWidth - (PXHorizontalInset * 2.0);
    CGFloat rowHeight = (PXHeight - (PXVerticalPadding * (PXRows + 1))) / PXRows;
    NSUInteger columns = ceilf(PXNumberOfPeople / PXRows);
    CGFloat columnWidth = (rowWidth - (PXHorizontalPadding * (columns - 1))) / columns;
    
    self.rowViews = [[NSMutableArray alloc] initWithCapacity:PXRows];
    self.rowGradientLayers = [[NSMutableArray alloc] initWithCapacity:PXRows];
    
    for (NSUInteger row = 0; row < PXRows; row++) {
        NSMutableDictionary *views = [[NSMutableDictionary alloc] init];
        [self.rowViews addObject:views];
        
        for (NSUInteger i = 0; i < 2; i++) {
            NSString *key = (i == 0) ? PXSolidView : PXGradientView;
            UIView *rowView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, rowWidth, rowHeight)];
            views[key] = rowView;
            
            for (NSUInteger column = 0; column < columns; column++) {
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake((columnWidth + PXHorizontalPadding) * column, 0.0, columnWidth, rowHeight)];
                imageView.contentMode = UIViewContentModeScaleAspectFit;
                [rowView addSubview:imageView];
                
                if (i == 1) {
                    imageView.alpha = 0.0;
                }
            }
            if (i == 0) {
                CALayer *solidLayer = [CAGradientLayer layer];
                solidLayer.frame = CGRectMake(0.0, (gradientHeight * row) + PXVerticalPadding, PXWidth, gradientHeight);
                solidLayer.backgroundColor = [UIColor colorWithWhite:0.76 alpha:1.0].CGColor;
                rowView.center = CGPointMake(solidLayer.bounds.size.width * 0.5,
                                             solidLayer.bounds.size.height * 0.5);
                solidLayer.mask = rowView.layer;
                [self.contentView.layer addSublayer:solidLayer];
            } else {
                CAGradientLayer *gradientLayer = [CAGradientLayer layer];
                gradientLayer.frame = CGRectMake(0.0, (gradientHeight * row) + PXVerticalPadding, PXWidth, gradientHeight);
                rowView.center = CGPointMake(gradientLayer.bounds.size.width * 0.5,
                                             gradientLayer.bounds.size.height * 0.5);
                gradientLayer.mask = rowView.layer;
                gradientLayer.startPoint = CGPointMake(0.0 - row, 0.5);
                gradientLayer.endPoint = CGPointMake(PXRows - row, 0.5);
                [self.contentView.layer addSublayer:gradientLayer];
                [self.rowGradientLayers addObject:gradientLayer];
            }
        }
    }
}

- (void)updateGradient {
    NSMutableArray *locations = [NSMutableArray array];
    for (NSDictionary *dictionary in self.percentileColors) {
        NSNumber *percentile = dictionary[PXGaugePercentile];
        CGFloat location = percentile.floatValue / 100.0;
        [locations addObject:@(location)];
    }
    for (CAGradientLayer *gradientLayer in self.rowGradientLayers) {
        gradientLayer.colors = [self.percentileColors valueForKey:PXGaugeColor];
        gradientLayer.locations = locations;
    }
}

- (void)setGenderType:(GenderType)genderType {
    for (NSUInteger row = 0; row < self.rowViews.count; row++) {
        NSDictionary *rowViews = self.rowViews[row];
        UIView *solidViews = rowViews[PXSolidView];
        UIView *gradientViews = rowViews[PXGradientView];
        
        BOOL oddRow = row % 2;
        
        for (NSUInteger column = 0; column < solidViews.subviews.count; column++) {
            BOOL oddColumn = column % 2;
            
            NSString *imageName;
            if (genderType == GenderTypeNone) {
                // Mix male and female with alternating rows and columns
                if (oddRow) {
                    imageName = oddColumn ? @"person-female" : @"person-male";
                } else {
                    imageName = oddColumn ? @"person-male" : @"person-female";
                }
            } else {
                if (genderType == GenderTypeMale) {
                    imageName = @"person-male";
                } else if (genderType == GenderTypeFemale) {
                    imageName = @"person-female";
                }
            }
            UIImageView *solidImageView = solidViews.subviews[column];
            solidImageView.image = [UIImage imageNamed:imageName];
            UIImageView *gradientImageView = gradientViews.subviews[column];
            gradientImageView.image = [UIImage imageNamed:imageName];
        }
    }
    _genderType = genderType;
}

- (void)updatedPercentile {
    CGFloat decimal = self.percentile / 100.0;
    NSUInteger peopleBelowRisk = roundf(PXNumberOfPeople * decimal);
    NSTimeInterval duration = 0.15;
    NSUInteger columns = ceilf(PXNumberOfPeople / PXRows);
    
    for (NSUInteger person = 0; person < PXNumberOfPeople; person++) {
        NSUInteger column = person % columns;
        NSUInteger row = floor(person / columns);
        
        NSDictionary *rowViews = self.rowViews[row];
        UIView *solidViews = rowViews[PXSolidView];
        UIImageView *solidImageView = solidViews.subviews[column];
        UIView *gradientViews = rowViews[PXGradientView];
        UIImageView *gradientImageView = gradientViews.subviews[column];
        
        [solidImageView.layer removeAllAnimations];
        [gradientImageView.layer removeAllAnimations];
        
        solidImageView.transform = CGAffineTransformIdentity;
        gradientImageView.transform = CGAffineTransformIdentity;
        
        solidImageView.alpha = 1.0;
        gradientImageView.alpha = 0.0;
        
        if (person < peopleBelowRisk) {
            [UIView animateWithDuration:duration
                                  delay:(duration * 0.5) * person
                                options:0
                             animations:^{
                                 solidImageView.alpha = 0.0;
                                 gradientImageView.alpha = 1.0;
                                 
                                 solidImageView.transform = CGAffineTransformMakeScale(1.2, 1.2);
                                 gradientImageView.transform = CGAffineTransformMakeScale(1.2, 1.2);
                             } completion:^(BOOL finished) {
                                 if (finished) {
                                     [UIView animateWithDuration:duration animations:^{
                                         solidImageView.transform = CGAffineTransformIdentity;
                                         gradientImageView.transform = CGAffineTransformIdentity;
                                     }];
                                 }
                             }];
        }
    }
}

@end
