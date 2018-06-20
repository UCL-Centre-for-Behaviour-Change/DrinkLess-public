//
//  PXNumberFieldDelegate.m
//  drinkless
//
//  Created by Edward Warrender on 07/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXNumberFieldDelegate.h"

@implementation PXNumberFieldDelegate

- (id)init {
    self = [super init];
    if (self) {
        _numberFormatter = [[NSNumberFormatter alloc] init];
        _numberFormatter.locale = [NSLocale currentLocale];
        _numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    }
    return self;
}

- (instancetype)initWithDecimalPlaces:(NSInteger)decimalPlaces {
    self = [self init];
    if (self) {
        self.decimalPlaces = decimalPlaces;
    }
    return self;
}

- (void)setDecimalPlaces:(NSInteger)decimalPlaces {
    _decimalPlaces = decimalPlaces;
    
    self.numberFormatter.maximumFractionDigits = decimalPlaces;
    self.numberFormatter.minimumFractionDigits = decimalPlaces;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (string.length > 1) {
        string = [string stringByReplacingOccurrencesOfString:self.numberFormatter.groupingSeparator withString:@""];
        NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:string];
        string = [self.numberFormatter stringFromNumber:number];
        range.length = string.length;
    }
    
    NSInteger previousCursorOffset = [textField offsetFromPosition:textField.beginningOfDocument
                                                        toPosition:textField.selectedTextRange.start];
    NSUInteger previousLength = textField.text.length;
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    text = [text stringByReplacingOccurrencesOfString:self.numberFormatter.groupingSeparator withString:@""];
    text = [text stringByReplacingOccurrencesOfString:self.numberFormatter.decimalSeparator withString:@""];
    
    CGFloat decimal = text.floatValue / powf(10.0, self.numberFormatter.maximumFractionDigits);
    textField.text = [self.numberFormatter stringFromNumber:@(decimal)];
    NSUInteger newLength = textField.text.length;
    
    if (previousCursorOffset != previousLength) {
        NSInteger delta = newLength - previousLength;
        NSInteger newCursorOffset = MAX(0, MIN(newLength, previousCursorOffset + delta));
        UITextPosition *textPosition = [textField positionFromPosition:textField.beginningOfDocument
                                                                offset:newCursorOffset];
        textField.selectedTextRange = [textField textRangeFromPosition:textPosition
                                                            toPosition:textPosition];
    }
    if ([self.delegate respondsToSelector:@selector(changedValue:)]) {
        [self.delegate changedValue:decimal];
    }
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([self.delegate respondsToSelector:@selector(finishedEditingTextField:)]) {
        [self.delegate finishedEditingTextField:textField];
    }
}

@end
