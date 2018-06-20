//
//  PXTabView.m
//  drinkless
//
//  Created by Edward Warrender on 30/01/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXTabView.h"
#import "PXSeparatorView.h"
#import "PXTabButton.h"

@interface PXTabView ()

@property (strong, nonatomic) NSMutableArray *tabButtons;
@property (strong, nonatomic) PXSeparatorView *bottomSeperatorView;

@end

@implementation PXTabView

- (void)setTitles:(NSArray *)titles {
    _titles = titles;
    
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    
    [self addSubview:self.bottomSeperatorView];
    NSDictionary *views = NSDictionaryOfVariableBindings(_bottomSeperatorView);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_bottomSeperatorView]|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_bottomSeperatorView]|" options:0 metrics:nil views:views]];
    
    self.tabButtons = [NSMutableArray arrayWithCapacity:titles.count];
    
    UIView *previousView = nil;
    for (NSInteger i = 0; i < titles.count; i++) {
        PXTabButton *button = [[PXTabButton alloc] init];
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        button.normalColor = [UIColor colorWithWhite:0.84 alpha:1.0];
        button.selectedColor = [UIColor colorWithWhite:0.94 alpha:1.0];
        [button setTitleColor:[UIColor colorWithWhite:0.33 alpha:1.0] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        
        [button setTitle:titles[i] forState:UIControlStateNormal];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button addTarget:self action:@selector(pressedTabButton:) forControlEvents:UIControlEventTouchDown];
        button.tag = i;
        [self addSubview:button];
        [self.tabButtons addObject:button];
        
        UIView *view = button;
        NSDictionary *views;
        if (previousView) {
            PXSeparatorView *separatorView = [[PXSeparatorView alloc] init];
            separatorView.backgroundColor = [UIColor colorWithWhite:0.7 alpha:1.0];
            separatorView.translatesAutoresizingMaskIntoConstraints = NO;
            [separatorView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            [self addSubview:separatorView];
            
            views = NSDictionaryOfVariableBindings(separatorView, previousView, view);
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[previousView][separatorView][view(==previousView)]" options:0 metrics:nil views:views]];
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[separatorView]|" options:0 metrics:nil views:views]];
        } else {
            views = NSDictionaryOfVariableBindings(view);
        }
        if (titles.count == 1) { // Single control
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:views]];
        }
        else if (i == 0) { // First control
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]" options:0 metrics:nil views:views]];
        }
        else if (i == titles.count - 1) { // Last control
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[view]|" options:0 metrics:nil views:views]];
        }
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:views]];
        previousView = view;
    }
    self.selectedIndex = 0;
}

- (PXSeparatorView *)bottomSeperatorView {
    if (!_bottomSeperatorView) {
        _bottomSeperatorView = [[PXSeparatorView alloc] init];
        _bottomSeperatorView.backgroundColor = [UIColor colorWithWhite:0.7 alpha:1.0];
        _bottomSeperatorView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _bottomSeperatorView;
}

- (void)pressedTabButton:(UIButton *)sender {
    if (!sender.selected) {
        self.selectedIndex = sender.tag;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    
    [self bringSubviewToFront:self.bottomSeperatorView];
    
    for (NSInteger i = 0; i < self.tabButtons.count; i++) {
        UIButton *button = self.tabButtons[i];
        button.selected = (button.tag == selectedIndex);
        if (button.selected) {
            [self bringSubviewToFront:button];
        }
    }
}

@end
