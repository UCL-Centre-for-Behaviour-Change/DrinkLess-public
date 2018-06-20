//
//  PXQuantityControl.m
//  drinkless
//
//  Created by Edward Warrender on 07/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXQuantityControl.h"

@interface PXQuantityControl ()

@property (weak, nonatomic) IBOutlet UIButton *minusButton;
@property (weak, nonatomic) IBOutlet UIButton *plusButton;
@property (weak, nonatomic) IBOutlet UILabel *quantityLabel;
@property (weak, nonatomic) UIButton *heldButton;
@property (strong, nonatomic) NSTimer *timer;

@end

@implementation PXQuantityControl

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        UINib *nib = [UINib nibWithNibName:@"PXQuantityControl" bundle:nil];
        UIView *view = [nib instantiateWithOwner:self options:nil].firstObject;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:view];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:views]];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.layer.cornerRadius = 4.0;
    self.layer.borderWidth = 1.0;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.layer.shouldRasterize = YES;
    
    _minimumValue = 1;
    _maximumValue = NSIntegerMax;
    self.value = self.minimumValue;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    
    self.layer.borderColor = self.tintColor.CGColor;
}

#pragma mark - Properties

- (void)setValue:(NSInteger)value {
    if (value < self.minimumValue || value > self.maximumValue) {
        return;
    }
    _value = value;
    self.quantityLabel.text = [NSString stringWithFormat:@"%ld", (long)self.value];
    [self checkEnabled];
}

- (void)setMinimumValue:(NSInteger)minimumValue {
    _minimumValue = minimumValue;
    
    [self checkLimits];
    [self checkEnabled];
}

- (void)setMaximumValue:(NSInteger)maximumValue {
    _maximumValue = maximumValue;
    
    [self checkLimits];
    [self checkEnabled];
}

- (void)checkLimits {
    if (self.value < self.minimumValue) {
        self.value = self.minimumValue;
    } else if (self.value > self.maximumValue) {
        self.value = self.maximumValue;
    }
}

- (void)checkEnabled {
    self.minusButton.enabled = _value > self.minimumValue;
    self.plusButton.enabled = _value < self.maximumValue;
}

#pragma mark - User actions

- (IBAction)touchDownButton:(id)sender {
    if (!self.timer) {
        self.heldButton = sender;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.175 target:self selector:@selector(triggerButton:) userInfo:nil repeats:YES];
    }
    [self triggerButton:self.timer];
}

- (IBAction)touchUpButton:(id)sender {
    self.heldButton = nil;
    [self.timer invalidate];
    self.timer = nil;
}

- (void)triggerButton:(NSTimer *)timer {
    if (self.heldButton == self.minusButton) {
        self.value--;
    } else if (self.heldButton == self.plusButton) {
        self.value++;
    }
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end
