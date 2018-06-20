//
//  UIViewController+Swipe.m
//  drinkless
//
//  Created by Edward Warrender on 29/04/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "UIViewController+Swipe.h"
#import <objc/runtime.h>

@interface UIViewController ()

@property (strong, nonatomic) UISwipeGestureRecognizer *leftSwipeRecognizer;
@property (strong, nonatomic) UISwipeGestureRecognizer *rightSwipeRecognizer;
@property (copy, nonatomic) PXBlockCallback callback;

@end

@implementation UIViewController (Swipe)

- (void)addSwipeWithCallback:(PXBlockCallback)callback {
    if (!self.leftSwipeRecognizer) {
        self.leftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureRecognized:)];
        self.leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.view addGestureRecognizer:self.leftSwipeRecognizer];
    }
    if (!self.rightSwipeRecognizer) {
        self.rightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureRecognized:)];
        self.rightSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:self.rightSwipeRecognizer];
    }
    self.callback = callback;
}

- (void)swipeGestureRecognized:(UISwipeGestureRecognizer *)recognizer {
    if (self.callback) {
        self.callback(recognizer.direction);
    }
}

#pragma mark - Properties

- (void)setLeftSwipeRecognizer:(UISwipeGestureRecognizer *)leftSwipeRecognizer {
    objc_setAssociatedObject(self, @selector(leftSwipeRecognizer), leftSwipeRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UISwipeGestureRecognizer *)leftSwipeRecognizer {
    return objc_getAssociatedObject(self, @selector(leftSwipeRecognizer));
}

- (void)setRightSwipeRecognizer:(UISwipeGestureRecognizer *)rightSwipeRecognizer {
    objc_setAssociatedObject(self, @selector(rightSwipeRecognizer), rightSwipeRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UISwipeGestureRecognizer *)rightSwipeRecognizer {
    return objc_getAssociatedObject(self, @selector(rightSwipeRecognizer));
}

- (void)setCallback:(PXBlockCallback)callback {
    objc_setAssociatedObject(self, @selector(callback), callback, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (PXBlockCallback)callback {
    return objc_getAssociatedObject(self, @selector(callback));
}

@end
