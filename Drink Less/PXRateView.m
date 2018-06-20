//
//  PXRateView.m
//  drinkless
//
//  Created by Edward Warrender on 10/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXRateView.h"
#import "PXSolidButton.h"

@interface PXRateView ()

@property (weak, nonatomic) IBOutlet PXSolidButton *solidButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation PXRateView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        UINib *nib = [UINib nibWithNibName:@"PXRateView" bundle:nil];
        UIView *view = [nib instantiateWithOwner:self options:nil].firstObject;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:view];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (void)setHelpful:(BOOL)helpful {
    _helpful = helpful;
    
    self.titleLabel.text = helpful ? @"Yes" : @"No";
    
    NSString *direction = helpful ? @"up" : @"down";
    NSString *imageName = [NSString stringWithFormat:@"thumbs-%@", direction];
    NSString *normalImageName = [NSString stringWithFormat:@"%@-off", imageName];
    NSString *selectedImageName = [NSString stringWithFormat:@"%@-on", imageName];
    [self.solidButton setImage:[UIImage imageNamed:normalImageName] forState:UIControlStateNormal];
    [self.solidButton setImage:[UIImage imageNamed:selectedImageName] forState:UIControlStateSelected];
    self.solidButton.selectedColor = helpful ? [UIColor drinkLessGreenColor] : [UIColor goalRedColor];
}

- (void)setSelected:(BOOL)selected {
    _selected = selected;
    
    UIColor *selectedColor = self.isHelpful ? [UIColor drinkLessGreenColor] : [UIColor goalRedColor];
    self.titleLabel.textColor = selected ? selectedColor : [UIColor colorWithWhite:0.55 alpha:1.0];
    self.solidButton.selected = selected;
}

- (IBAction)pressedButton:(id)sender {
    [self.delegate selectedRateView:self];
}

@end
