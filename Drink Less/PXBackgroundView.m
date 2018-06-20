//
//  PXBackgroundView.m
//  drinkless
//
//  Created by Edward Warrender on 13/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXBackgroundView.h"

@interface PXBackgroundView ()

@property (nonatomic) CGFloat lineWidth;
@property (strong, nonatomic) CALayer *separatorLayer;

@end

static CGSize const PXCornerRadius = {5.0, 5.0};

@implementation PXBackgroundView

- (instancetype)initWithPosition:(PXBackgroundViewPosition)position {
    self = [super init];
    if (self) {
        self.opaque = YES;
        _position = position;
        _lineWidth = 1.0 / [UIScreen mainScreen].scale;
        
        if (position == PXBackgroundViewPositionTop ||
            position == PXBackgroundViewPositionMiddle) {
            _separatorLayer = [CALayer layer];
            [self.layer addSublayer:_separatorLayer];
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = CGRectMake(self.separatorInset.left,
                             self.frame.size.height - self.lineWidth,
                             self.frame.size.width - self.separatorInset.left - self.separatorInset.right,
                             self.lineWidth);
    self.separatorLayer.frame = rect;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    
    UIBezierPath *path = [self bezierPathForPosition:self.position];
    if (path) {
        CGContextAddPath(context, path.CGPath);
        CGContextFillPath(context);
    } else {
        CGContextFillRect(context, rect);
    }
    UIGraphicsEndImageContext();
}

- (UIBezierPath *)bezierPathForPosition:(PXBackgroundViewPosition)position {
    UIRectCorner corners = [self cornersForPosition:position];
    if (corners == NSNotFound) {
        return nil;
    }
    return [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                 byRoundingCorners:corners
                                       cornerRadii:PXCornerRadius];
}

- (UIRectCorner)cornersForPosition:(PXBackgroundViewPosition)position {
    switch (position) {
        case PXBackgroundViewPositionTop:
            return UIRectCornerTopLeft | UIRectCornerTopRight;
        case PXBackgroundViewPositionBottom:
            return UIRectCornerBottomLeft | UIRectCornerBottomRight;
        case PXBackgroundViewPositionSingle:
            return UIRectCornerAllCorners;
        case PXBackgroundViewPositionMiddle:
        default:
            return NSNotFound;
    }
}

#pragma mark - Properties

- (void)setSeparatorColor:(UIColor *)separatorColor {
    _separatorColor = separatorColor;
    self.separatorLayer.backgroundColor = _separatorColor.CGColor;
}

- (void)setSeparatorInset:(UIEdgeInsets)separatorInset {
    _separatorInset = separatorInset;
    [self setNeedsLayout];
}

@end
