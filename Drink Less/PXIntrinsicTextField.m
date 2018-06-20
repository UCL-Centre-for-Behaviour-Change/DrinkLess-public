//
//  PXIntrinsicTextField.m
//  drinkless
//
//  Created by Edward Warrender on 26/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXIntrinsicTextField.h"

@implementation PXIntrinsicTextField

- (CGSize)textSize {
    NSDictionary *attributes = self.isEditing ? self.typingAttributes : self.defaultTextAttributes;
    return [self.text sizeWithAttributes:attributes];
}

- (CGRect)leftViewRectForBounds:(CGRect)bounds {
    CGRect leftViewRect = [super leftViewRectForBounds:bounds];
    CGFloat textWidth = [self textSize].width;
    CGFloat width = textWidth + leftViewRect.size.width;
    
    switch (self.textAlignment) {
        case NSTextAlignmentCenter: {
            CGFloat x = (bounds.size.width - width) / 2.0;
            if (leftViewRect.origin.x < x) {
                leftViewRect.origin.x = x;
            }
        } break;
        case NSTextAlignmentRight: {
            CGFloat x = bounds.size.width - width;
            if (leftViewRect.origin.x < x) {
                leftViewRect.origin.x = x;
            }
        } break;
        default:
            break;
    }
    return leftViewRect;
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds {
    CGRect rightViewRect = [super rightViewRectForBounds:bounds];
    CGFloat textWidth = [self textSize].width;
    CGFloat width = textWidth + rightViewRect.size.width;
    
    switch (self.textAlignment) {
        case NSTextAlignmentCenter: {
            CGFloat x = ((bounds.size.width - width) / 2.0) + textWidth;
            if (rightViewRect.origin.x > x) {
                rightViewRect.origin.x = x;
            }
        } break;
        case NSTextAlignmentLeft: {
            CGFloat x = width;
            if (rightViewRect.origin.x > x) {
                rightViewRect.origin.x = x;
            }
        } break;
        default:
            break;
    }
    return rightViewRect;
}

@end
