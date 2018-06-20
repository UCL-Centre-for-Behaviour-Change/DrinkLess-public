//
//  PXNumberFieldDelegate.h
//  drinkless
//
//  Created by Edward Warrender on 25/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>
#import <UIKit/UITextField.h>

@protocol PXNumberFieldChangeDelegate;

@interface PXNumberFieldDelegate : NSObject <UITextFieldDelegate>

- (instancetype)initWithDecimalPlaces:(NSInteger)decimalPlaces;

@property (nonatomic) NSInteger decimalPlaces;
@property (strong, nonatomic, readonly) NSNumberFormatter *numberFormatter;
@property (weak, nonatomic) id <PXNumberFieldChangeDelegate> delegate;

@end

@protocol PXNumberFieldChangeDelegate <NSObject>
@optional

- (void)changedValue:(CGFloat)value;
- (void)finishedEditingTextField:(UITextField *)textField;

@end
