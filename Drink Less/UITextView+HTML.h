//
//  UITextView+HTML.h
//  drinkless
//
//  Created by Edward Warrender on 16/04/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@interface UITextView (HTML)

- (void)loadHTMLString:(NSString *)string;

@end
