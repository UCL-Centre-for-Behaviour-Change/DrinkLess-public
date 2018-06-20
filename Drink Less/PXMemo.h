//
//  PXMemo.h
//  drinkless
//
//  Created by Chris Pritchard on 30/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <Foundation/Foundation.h>

@interface PXMemo : NSObject

@property (nonatomic, strong) NSString* filePath;
@property (nonatomic, strong) NSDate* recordedDate;
@property (nonatomic, strong) NSString* memoName;

- (id)initWithDict:(NSDictionary*)dict;
- (id)initWithFilePath:(NSString*)filePath recordedDate:(NSDate*)recordedDate memoName:(NSString*)memoName;
- (NSDictionary*)exportDict;

@end
