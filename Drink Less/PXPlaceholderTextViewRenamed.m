//
//  PXPlaceholderTextView.m
//  drinkless
//
//  Created by Edward Warrender on 15/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXPlaceholderTextViewRenamed.h"

@interface PXPlaceholderTextViewRenamed ()

@property (nonatomic, getter = shouldDisplayPlaceholder) BOOL displayPlaceholder;

@end

@implementation PXPlaceholderTextViewRenamed

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialise];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        [self initialise];
    }
    return self;
}

- (void)initialise {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:self];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:self];
}

- (void)setText:(NSString *)text {
    [super setText:text];
    [self checkIfNeedsPlaceholder];
}

- (void)textChanged:(NSNotification *)notification {
    [self checkIfNeedsPlaceholder];
}

- (void)setPlaceholder:(NSString *)placeholder {
    if ([_placeholder isEqualToString:placeholder]) {
        return;
    }
    _placeholder = placeholder;
    [self checkIfNeedsPlaceholder];
}

- (void)checkIfNeedsPlaceholder {
    self.displayPlaceholder = (self.placeholder && self.text.length == 0);
}

- (void)setDisplayPlaceholder:(BOOL)displayPlaceholder {
    if (_displayPlaceholder == displayPlaceholder) {
        return;
    }
    _displayPlaceholder = displayPlaceholder;
    [self setNeedsDisplay];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (self.displayPlaceholder) {
        rect.origin.x += self.textContainer.lineFragmentPadding - self.textContainerInset.left;
        rect.origin.y += self.textContainerInset.top;
        rect.size.width -= self.textContainer.lineFragmentPadding + self.textContainerInset.right;
        rect.size.height -= self.textContainerInset.bottom;
        
        NSDictionary *attributes = @{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.75 alpha:1.0],
                                     NSFontAttributeName: self.font};
        [self.placeholder drawInRect:rect withAttributes:attributes];
    }
}

@end
