//
//  PXPlaceholderView.m
//  drinkless
//
//  Created by Edward Warrender on 14/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXPlaceholderViewRenamed.h"
#import "PXSolidButton.h"

@interface PXPlaceholderViewRenamed ()

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *containerViews;
@property (strong, nonatomic) NSMutableArray *heightConstraints;

@end

@implementation PXPlaceholderViewRenamed

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        UINib *nib = [UINib nibWithNibName:@"PXPlaceholderViewRenamed" bundle:nil];
        UIView *view = [nib instantiateWithOwner:self options:nil].firstObject;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:view];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (void)setImage:(UIImage *)image title:(NSString *)title subtitle:(NSString *)subtitle footer:(NSAttributedString *)footer {
    [self setImage:image title:title subtitle:subtitle buttonTitle:nil footer:footer solid:NO target:nil action:nil];
}

- (void)setImage:(UIImage *)image title:(NSString *)title subtitle:(NSString *)subtitle buttonTitle:(NSString *)buttonTitle footer:(NSAttributedString *)footer solid:(BOOL)solid target:(id)target action:(SEL)action {
    
    self.imageView.image = image;
    self.titleLabel.text = title;
    self.subtitleLabel.text = subtitle;
    [self.button setTitle:buttonTitle forState:UIControlStateNormal];
    self.footerLabel.attributedText = footer;
    
    NSMutableArray *expandViews = [NSMutableArray array];
    if (image) {
        [expandViews addObject:self.imageView.superview];
    }
    if (title) {
        [expandViews addObject:self.titleLabel.superview];
    }
    if (subtitle) {
        [expandViews addObject:self.subtitleLabel.superview];
    }
    if (buttonTitle) {
        if (solid) {
            [self.button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            self.button.borderWidth = 0.0;
            self.button.borderColor = [UIColor clearColor];
            self.button.backgroundColor = self.window ? self.tintColor : nil;
        } else {
            [self.button setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            self.button.borderWidth = 1.0;
            self.button.borderColor = [UIColor colorWithWhite:0.75 alpha:1.0];
            self.button.backgroundColor = [UIColor clearColor];
        }
        [self.button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
        [expandViews addObject:self.button.superview];
    }
    if (footer) {
        [expandViews addObject:self.footerLabel.superview];
    }
    
    for (NSLayoutConstraint *constraint in self.heightConstraints) {
        [constraint.firstItem removeConstraint:constraint];
    }
    self.heightConstraints = [NSMutableArray array];
    for (UIView *containerView in self.containerViews) {
        BOOL shouldExpand = [expandViews containsObject:containerView];
        containerView.alpha = shouldExpand;
        
        if (!shouldExpand) {
            NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:containerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
            [containerView addConstraint:constraint];
            [self.heightConstraints addObject:constraint];
        }/* else {
            [containerView sizeToFit];
            CGFloat h = containerView.frame.size.height;
            NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:containerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:h];
            [containerView addConstraint:constraint];
            [self.heightConstraints addObject:constraint];
        }*/
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
