//
//  PXActionPlanCell.m
//  drinkless
//
//  Created by Edward Warrender on 17/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXActionPlanCell.h"
#import "PXActionPlanView.h"

static CGFloat const PXMargin = 15.0;

@implementation PXActionPlanCell

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.actionPlanView = [[PXActionPlanView alloc] init];
        self.actionPlanView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.actionPlanView];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_actionPlanView);
        NSDictionary *metrics = @{@"margin" : @(PXMargin)};
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-margin-[_actionPlanView]-(margin@999)-|" options:0 metrics:metrics views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[_actionPlanView]-(margin@999)-|" options:0 metrics:metrics views:views]];
    }
    return self;
}

@end
