//
//  PXProgressStepsView.m
//  drinkless
//
//  Created by Edward Warrender on 20/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXProgressStepsView.h"
#import "PXStepView.h"

@interface PXProgressStepsView ()

@property (strong, nonatomic) NSArray *stepViews;
@property (strong, nonatomic) NSArray *linkViews;

@end

@implementation PXProgressStepsView

- (void)setSteps:(NSArray *)steps {
    for (UIView *subview in self.subviews) {
        [subview removeFromSuperview];
    }
    
    NSMutableArray *stepViews = [NSMutableArray arrayWithCapacity:steps.count];
    NSMutableArray *linkViews = [[NSMutableArray alloc] init];
    __block PXStepView *previousView;
    [steps enumerateObjectsUsingBlock:^(NSString *step, NSUInteger index, BOOL *stop) {
        
        PXStepView *stepView = [[PXStepView alloc] init];
        stepView.translatesAutoresizingMaskIntoConstraints = NO;
        stepView.numberLabel.text = [NSString stringWithFormat:@"%li", (long)index + 1];
        stepView.titleLabel.text = step;
        [self addSubview:stepView];
        [stepViews addObject:stepView];
        
        NSDictionary *views;
        if (previousView) {
            UIView *linkView = [[UIView alloc] init];
            linkView.translatesAutoresizingMaskIntoConstraints = NO;
            [self insertSubview:linkView atIndex:0];
            [linkViews addObject:linkView];
            
            views = NSDictionaryOfVariableBindings(linkView, previousView, stepView);
            [self addConstraint:[NSLayoutConstraint constraintWithItem:linkView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:previousView.containerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:linkView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:stepView.containerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[linkView(2)]" options:0 metrics:nil views:views]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:linkView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:stepView.containerView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[previousView][stepView(==previousView)]" options:0 metrics:nil views:views]];
        } else {
            views = NSDictionaryOfVariableBindings(stepView);
        }
        if (steps.count == 1) { // Single step
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[stepView]-10-|" options:0 metrics:nil views:views]];
        }
        else if (index == 0) { // First step
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[stepView]" options:0 metrics:nil views:views]];
        }
        else if (index == steps.count - 1) { // Last step
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[stepView]-10-|" options:0 metrics:nil views:views]];
        }
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[stepView]-5-|" options:0 metrics:nil views:views]];
        previousView = stepView;
    }];
    self.linkViews = linkViews.copy;
    self.stepViews = stepViews.copy;
    _steps = steps;
}

- (void)setCurrentStep:(NSInteger)currentStep {
    [self.stepViews enumerateObjectsUsingBlock:^(PXStepView *stepView, NSUInteger index, BOOL *stop) {
        NSInteger step = index + 1;
        
        UIColor *color = nil;
        UIImage *image = nil;
        
        if (step == currentStep) {
            color = [UIColor drinkLessDarkGreyColor];
        } else if (step < currentStep) {
            color = [UIColor drinkLessGreenColor];
            image = [UIImage imageNamed:@"step-done"];
        } else if (step > currentStep) {
            color = [UIColor drinkLessLightGreyColor];
        }
        stepView.containerView.backgroundColor = color;
        stepView.titleLabel.textColor = color;
        stepView.imageView.image = image;
        
        BOOL hasImage = !(image == nil);
        stepView.numberLabel.hidden = hasImage;
        stepView.imageView.hidden = !hasImage;
    }];
    
    [self.linkViews enumerateObjectsUsingBlock:^(UIView *linkView, NSUInteger index, BOOL *stop) {
        NSInteger step = index + 1;
        
        UIColor *color = nil;
        if (step < currentStep) {
            color = [UIColor drinkLessGreenColor];
        } else {
            color = [UIColor drinkLessLightGreyColor];
        }
        linkView.backgroundColor = color;
    }];
    _currentStep = currentStep;
}

@end
