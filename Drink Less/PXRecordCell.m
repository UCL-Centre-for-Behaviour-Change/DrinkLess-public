//
//  PXRecordCell.m
//  drinkless
//
//  Created by Edward Warrender on 07/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXRecordCell.h"
#import "UIColor+DrinkLess.h"

@interface PXRecordCell ()

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (strong, nonatomic) UILabel *percentageLabel;
@property (strong, nonatomic) UILabel *volumeLabel;
@property (strong, nonatomic) UILabel *currencyLabel;

@end

@implementation PXRecordCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.iconImageView.tintColor = [UIColor drinkLessGreenColor];
    self.iconImageView.alpha = 0.5;
    self.iconImage = self.iconImageView.image;
    
    if (self.textField) {
        self.numberFieldDelegate = [[PXNumberFieldDelegate alloc] init];
        self.textField.delegate = self.numberFieldDelegate;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.accessoryView != nil) {
        CGRect frame = self.accessoryView.frame;
        frame.origin.x += 5;
        self.accessoryView.frame = frame;
    }
}

- (void)setIconImage:(UIImage *)iconImage {
    _iconImage = iconImage;
    self.iconImageView.image = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (UILabel *)percentageLabel {
    if (!_percentageLabel) {
        _percentageLabel = [[UILabel alloc] init];
        _percentageLabel.text = self.numberFieldDelegate.numberFormatter.percentSymbol;
        _percentageLabel.font = self.textField.font;
        _percentageLabel.textColor = UIColor.drinkLessGreenColor;//self.textField.textColor;
        [_percentageLabel sizeToFit];
    }
    return _percentageLabel;
}

- (UILabel *)volumeLabel {
    if (!_volumeLabel) {
        _volumeLabel = [[UILabel alloc] init];
        _volumeLabel.text = @"ml";
        _volumeLabel.font = self.textField.font;
        _volumeLabel.textColor = self.textField.textColor;
        [_volumeLabel sizeToFit];
    }
    return _volumeLabel;
}

- (UILabel *)currencyLabel {
    if (!_currencyLabel) {
        _currencyLabel = [[UILabel alloc] init];
        _currencyLabel.text = self.numberFieldDelegate.numberFormatter.currencySymbol;
        _currencyLabel.font = self.textField.font;
        _currencyLabel.textColor = UIColor.drinkLessGreenColor;//self.textField.textColor;
        [_currencyLabel sizeToFit];
    }
    return _currencyLabel;
}

- (void)setFormatType:(PXFormatType)formatType {
    _formatType = formatType;
    
    switch (formatType) {
        case PXFormatTypePercentage: {
            self.numberFieldDelegate.decimalPlaces = 1;
            self.textField.leftViewMode = UITextFieldViewModeNever;
            self.textField.leftView = nil;
            self.textField.rightViewMode = UITextFieldViewModeAlways;
            self.textField.rightView = self.percentageLabel;
            break;
        }
        case PXFormatTypeCurrency: {
            self.numberFieldDelegate.decimalPlaces = 2;
            self.textField.leftViewMode = UITextFieldViewModeAlways;
            self.textField.leftView = self.currencyLabel;
            self.textField.rightViewMode = UITextFieldViewModeNever;
            self.textField.rightView = nil;
            break;
        }
        case PXFormatTypeInteger: {
            self.numberFieldDelegate.decimalPlaces = 0;
            self.textField.leftViewMode = UITextFieldViewModeNever;
            self.textField.rightViewMode = UITextFieldViewModeNever;
            self.textField.leftView = nil;
            self.textField.rightView = nil;
            break;
        }
        case PXFormatTypeVolume: {
            self.numberFieldDelegate.decimalPlaces = 0;
            self.textField.leftViewMode = UITextFieldViewModeNever;
            self.textField.leftView = nil;
            self.textField.rightViewMode = UITextFieldViewModeAlways;
            self.textField.rightView = self.volumeLabel;
            break;
        }
        default:
            break;
    }
}

@end
