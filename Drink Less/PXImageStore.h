//
//  PXImageStore.h
//  drinkless
//
//  Created by Edward Warrender on 08/05/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

@interface PXImageStore : NSObject

+ (instancetype)sharedImageStore;
+ (void)resetSharedImageStore;

- (UIImage *)imageForKey:(NSString *)key;
- (NSString *)addImage:(UIImage *)image;
- (void)setImage:(UIImage *)image forKey:(NSString *)key;
- (void)removeImageForKey:(NSString *)key;

@end
