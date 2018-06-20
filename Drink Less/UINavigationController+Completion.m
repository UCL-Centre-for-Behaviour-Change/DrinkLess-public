//
//  UINavigationController+Completion.m
//  drinkless
//
//  Created by Edward Warrender on 07/05/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "UINavigationController+Completion.h"
#import <objc/runtime.h>

@interface UINavigationController () <UINavigationControllerDelegate>

@property (copy, nonatomic) void (^completion)(void);

@end

@implementation UINavigationController (Completion)

- (UIViewController *)popViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion {
    self.completion = completion;
    self.delegate = self;
    return [self popViewControllerAnimated:animated];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.delegate = nil;
    if (self.completion) {
        self.completion();
    }
}

#pragma mark - Properties

- (void)setCompletion:(void (^)(void))completion {
    objc_setAssociatedObject(self, @selector(completion), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(void))completion {
    return objc_getAssociatedObject(self, @selector(completion));
}

@end
