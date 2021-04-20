//
//  UITextView+HTML.m
//  drinkless
//
//  Created by Edward Warrender on 16/04/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "UITextView+HTML.h"

@implementation UITextView (HTML)

- (void)loadHTMLString:(NSString *)string {
    self.textContainer.lineFragmentPadding = 0.0;
    self.textContainerInset = UIEdgeInsetsMake(1.0, 0.0, 1.0, 0.0);
    
    NSString *style = [NSString stringWithFormat:@"<style>body{color: %@; text-align: %@; font-family: '%@'; font-size: %fpx;}</style>", [self rgbStringFromColor:self.textColor], [self cssTextAlignment], @"HelveticaNeue" /* self.font.fontName */, self.font.pointSize];
    string = [string stringByAppendingString:style];
    
    self.attributedText = [[NSAttributedString alloc] initWithData:[string dataUsingEncoding:NSUnicodeStringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType} documentAttributes:nil error:nil];
}

- (NSString *)rgbStringFromColor:(UIColor *)color {
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    return [NSString stringWithFormat:@"rgb(%li, %li, %li)",
            (long)[self colorFromDecimal:red],
            (long)[self colorFromDecimal:green],
            (long)[self colorFromDecimal:blue]];
}

- (NSInteger)colorFromDecimal:(CGFloat)decimal {
    return (long)roundf(decimal * 255);
}

- (NSString *)cssTextAlignment {
    switch (self.textAlignment) {
        case NSTextAlignmentLeft:
            return @"left";
        case NSTextAlignmentCenter:
            return @"center";
        case NSTextAlignmentRight:
            return @"right";
        default:
            return @"inherit";
    }
}

@end
