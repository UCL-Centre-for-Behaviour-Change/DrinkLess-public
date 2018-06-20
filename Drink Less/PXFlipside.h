//
//  PXFlipside.h
//  drinkless
//
//  Created by Edward Warrender on 12/12/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

@interface PXFlipside : NSObject <NSCopying, NSCoding>

@property (strong, nonatomic) NSString *positiveText;
@property (strong, nonatomic) NSString *negativeText;
@property (strong, nonatomic) UIImage *positiveImage;
@property (strong, nonatomic) UIImage *negativeImage;
@property (strong, nonatomic) NSString *positiveImageID;
@property (strong, nonatomic) NSString *negativeImageID;
@property (nonatomic, readonly) NSString *errorMessage;

@end
