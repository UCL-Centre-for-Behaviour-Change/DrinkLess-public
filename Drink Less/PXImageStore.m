//
//  PXImageStore.m
//  drinkless
//
//  Created by Edward Warrender on 08/05/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXImageStore.h"

@interface PXImageStore ()

@property (strong, nonatomic) NSCache *cache;
@property (strong, nonatomic) NSString *directoryPath;

@end

@implementation PXImageStore

+ (instancetype)sharedImageStore {
    static PXImageStore *sharedImageStore = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedImageStore = [[self alloc] init];
    });
    return sharedImageStore;
}

+ (void)resetSharedImageStore {
    PXImageStore *imageStore = [PXImageStore sharedImageStore];
    [imageStore.cache removeAllObjects];
    
    [[NSFileManager defaultManager] removeItemAtPath:imageStore.directoryPath error:nil];
    imageStore.directoryPath = nil;
}

- (id)init {
    self = [super init];
    if (self) {
        _cache = [[NSCache alloc] init];
    }
    return self;
}

#pragma mark - Internal

- (NSString *)directoryPath {
    if (!_directoryPath) {
        NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
        _directoryPath = [documentsDirectory stringByAppendingPathComponent:@"PXImageStore"];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:_directoryPath]) {
            [fileManager createDirectoryAtPath:_directoryPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
    }
    return _directoryPath;
}

- (NSString *)imagePathForKey:(NSString *)key {
    return [self.directoryPath stringByAppendingPathComponent:key];
}

#pragma mark - Actions

- (UIImage *)imageForKey:(NSString *)key {
    UIImage *image = [self.cache objectForKey:key];
    if (!image) {
        image = [UIImage imageWithContentsOfFile:[self imagePathForKey:key]];
        if (image) {
            [self.cache setObject:image forKey:key];
        }
    }
    return image;
}

- (NSString *)addImage:(UIImage *)image {
    NSString *key = [NSUUID UUID].UUIDString;
    [self setImage:image forKey:key];
    return key;
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key {
    [self.cache setObject:image forKey:key];
    
    NSString *imagePath = [self imagePathForKey:key];
    NSData *data = UIImageJPEGRepresentation(image, 0.9);
    [data writeToFile:imagePath atomically:YES];
}

- (void)removeImageForKey:(NSString *)key {
    [self.cache removeObjectForKey:key];
    
    NSString *path = [self imagePathForKey:key];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

@end
