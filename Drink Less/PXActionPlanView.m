//
//  PXActionPlanView.m
//  drinkless
//
//  Created by Edward Warrender on 16/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXActionPlanView.h"
#import "PXArrowView.h"

@interface PXActionPlanView ()

@property (weak, nonatomic) IBOutlet UILabel *ifTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *thenTitleLabel;
@property (weak, nonatomic) IBOutlet UIView *thenContainerView;
@property (strong, nonatomic) NSLayoutConstraint *thenHeightConstraint;
@property (strong, nonatomic) PXArrowView *arrowView;

@end

@implementation PXActionPlanView

- (id)init {
    self = [super init];
    if (self) {
        [self initialConfiguration];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialConfiguration];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.ifTextLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.ifTextLabel.bounds);
    self.thenTextLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.thenTextLabel.bounds);
}

- (void)initialConfiguration {
    UINib *nib = [UINib nibWithNibName:@"PXActionPlanView" bundle:nil];
    UIView *view = [nib instantiateWithOwner:self options:nil].firstObject;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:view];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:views]];
    
    UIColor *ifColor = [UIColor blackColor];
    UIColor *thenColor = [UIColor drinkLessGreenColor];
    self.ifTitleLabel.textColor = ifColor;
    self.ifTextLabel.textColor = ifColor;
    self.thenTitleLabel.textColor = thenColor;
    self.thenTextLabel.textColor = thenColor;
    
    self.arrowView = [[PXArrowView alloc] init];
    [self addSubview:self.arrowView];
}

#pragma mark - Properties

- (void)setCollapsed:(BOOL)collapsed {
    [self setCollapsed:collapsed animated:NO];
}

- (void)setCollapsed:(BOOL)collapsed animated:(BOOL)animated {
    [self setCollapsed:collapsed animated:animated delay:0.0];
}

- (void)setCollapsed:(BOOL)collapsed animated:(BOOL)animated delay:(NSTimeInterval)delay {
    _collapsed = collapsed;
    if (collapsed) {
        if (!self.thenHeightConstraint) {
            self.thenHeightConstraint = [NSLayoutConstraint constraintWithItem:self.thenContainerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:0.0 constant:0.0];
            [self.thenContainerView addConstraint:self.thenHeightConstraint];
        }
    } else {
        if (self.thenHeightConstraint) {
            [self.thenContainerView removeConstraint:self.thenHeightConstraint];
            self.thenHeightConstraint = nil;
        }
    }
    void (^updateBlock)() = ^{
        [self setNeedsLayout];
        [self layoutIfNeeded];
        [self updateArrowView];
        self.thenContainerView.alpha = collapsed ? 0.0: 1.0;
    };
    if (animated) {
        [UIView animateWithDuration:0.8
                              delay:collapsed ? 0.0 : delay
             usingSpringWithDamping:0.5
              initialSpringVelocity:0.0
                            options:0
                         animations:updateBlock
                         completion:^(BOOL finished) {
                         }];
    } else {
        updateBlock();
    }
}

- (void)updateArrowView {
    [UIView animateWithDuration:0.3 animations:^{
        self.arrowView.alpha = self.isCollapsed ? 0.0 : 1.0;
    }];
    if (!self.isCollapsed) {
        CGFloat margin = 4.0;
        CGRect ifRect = [self convertRect:self.ifTitleLabel.frame fromView:self.ifTitleLabel.superview];
        CGRect thenRect = [self convertRect:self.thenTitleLabel.frame fromView:self.thenTitleLabel.superview];
        CGPoint startPoint = CGPointMake(CGRectGetMidX(ifRect), CGRectGetMaxY(ifRect) + margin);
        CGPoint endPoint = CGPointMake(CGRectGetMinX(thenRect) - margin, CGRectGetMidY(thenRect));
        CGPoint midPoint = CGPointMake(ifRect.origin.x, endPoint.y);
        [self.arrowView animateWithStartPoint:startPoint midPoint:midPoint endPoint:endPoint];
    }
}

@end
