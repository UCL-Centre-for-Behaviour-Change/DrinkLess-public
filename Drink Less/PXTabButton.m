//
//  PXTabButton.m
//  drinkless
//
//  Created by Edward Warrender on 05/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXTabButton.h"

@implementation PXTabButton

- (id)init {
    self = [super init];
    if (self) {
        [self initialConfiguration];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initialConfiguration];
}

- (void)initialConfiguration {
    self.adjustsImageWhenHighlighted = NO;
    self.adjustsImageWhenDisabled = NO;
    self.contentEdgeInsets = UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0);
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor = 0.1;
    
    if (!self.normalColor) {
        self.normalColor = [UIColor colorWithWhite:0.97 alpha:0.0];
    }
    if (!self.selectedColor) {
        self.selectedColor = [UIColor colorWithRed:188/255.0 green:191/255.0 blue:196/255.0 alpha:1.0];
    }
    
    [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    
    [self updateAppearanceForCurrentState];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    [self updateAppearanceForCurrentState];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    [self setHighlighted:highlighted animated:YES];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    NSTimeInterval duration = animated ? 0.15 : 0.0;
    [UIView animateWithDuration:duration animations:^{
        [self updateAppearanceForCurrentState];
    }];
}

- (void)updateAppearanceForCurrentState {
    switch (self.state) {
        case UIControlStateNormal:
            self.backgroundColor = self.normalColor;
            break;
        case UIControlStateHighlighted:
        case UIControlStateSelected:
            self.backgroundColor = self.selectedColor;
            break;
            
        default:
            break;
    }
}

@end
