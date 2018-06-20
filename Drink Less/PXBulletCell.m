//
//  PXBulletCell.m
//  drinkless
//
//  Created by Edward Warrender on 04/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXBulletCell.h"

@interface PXBulletCell () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *dotView;
@property (strong, nonatomic) CALayer *dotLayer;

@end

@implementation PXBulletCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.dotLayer = [CALayer layer];
    self.dotLayer.anchorPoint = CGPointZero;
    self.dotLayer.bounds = self.dotView.bounds;
    self.dotLayer.cornerRadius = CGRectGetMidX(self.dotView.bounds);
    self.dotLayer.rasterizationScale = [UIScreen mainScreen].scale;
    self.dotLayer.shouldRasterize = YES;
    self.dotLayer.opacity = 0.65;
    [self.dotView.layer addSublayer:self.dotLayer];
}

#pragma mark - Properties

- (void)setDotColor:(UIColor *)dotColor {
    _dotColor = dotColor;
    
    self.dotLayer.backgroundColor = dotColor.CGColor;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    // Prevents editing text view when reordering
    if (editing) {
        [self.textView resignFirstResponder];
    }
    self.textView.userInteractionEnabled = !editing;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        NSString *remaining = [textView.text substringToIndex:range.location];
        if (remaining.length != 0) {
            NSString *newline = [textView.text substringFromIndex:range.location];
            textView.text = remaining;
            [self textViewDidChange:textView];
            [self.delegate insertLine:newline fromCell:self];
        }
        return NO;
    }
    if ([text isEqualToString:@""] && range.location == 0 && range.length == 0) {
        [self.delegate deleteLine:textView.text fromCell:self];
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self.delegate changedTextViewInCell:self];
}

@end
