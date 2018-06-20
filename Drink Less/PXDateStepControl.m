//
//  PXDateStepControl.m
//  drinkless
//
//  Created by Edward Warrender on 13/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXDateStepControl.h"
#import "NSDate+DrinkLess.h"

@interface PXDateStepControl ()

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@end

@implementation PXDateStepControl

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        UINib *nib = [UINib nibWithNibName:@"PXDateStepControl" bundle:nil];
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
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateFormat = @"EEE d MMM";
    self.date = nil;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(0.0, 44.0);
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    
    [self tintImageForButton:self.leftButton];
    [self tintImageForButton:self.rightButton];
}

- (void)tintImageForButton:(UIButton *)button {
    UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [button setImage:image forState:UIControlStateNormal];
}

#pragma mark - Properties

- (void)setDate:(NSDate *)date {
    if (!date) {
        date = [NSDate strictDateFromToday];
    }
    _date = date;
    
    BOOL isToday = [NSDate isDate:date sameDayAsDate:[NSDate date]];
    self.rightButton.enabled = self.allowsFutureDates ? YES : !isToday;
    if (isToday) {
        self.dateLabel.text = @"Today";
    } else {
        self.dateLabel.text = [self.dateFormatter stringFromDate:self.date];
    }
}

#pragma mark - Actions

- (IBAction)pressedButton:(UIButton *)button {
    if (button == self.leftButton) {
        self.date = [NSDate previousDayFromDate:self.date];
    } else if (button == self.rightButton) {
        self.date = [NSDate nextDayFromDate:self.date];
    }
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)decrease {
    if (self.leftButton.enabled) {
        [self pressedButton:self.leftButton];
    }
}

- (void)increase {
    if (self.rightButton.enabled) {
        [self pressedButton:self.rightButton];
    }
}

@end
