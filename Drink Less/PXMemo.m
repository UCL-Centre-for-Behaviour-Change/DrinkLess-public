//
//  PXMemo.m
//  drinkless
//
//  Created by Chris Pritchard on 30/09/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXMemo.h"

@implementation PXMemo

- (id)initWithDict:(NSDictionary*)dict {
    self = [super init];
    if (self) {
        self.filePath = dict[@"filepath"];
        self.recordedDate = dict[@"recordedDate"];
        self.memoName = dict[@"memoName"];
    }
    
    return self;
}

- (id)initWithFilePath:(NSString*)filePath recordedDate:(NSDate*)recordedDate memoName:(NSString*)memoName {
    self = [super init];
    if (self) {
        self.filePath = filePath;
        self.recordedDate = recordedDate;
        self.memoName = memoName;
    }
    
    return self;
}

- (NSDictionary*)exportDict {
    return @{@"filepath"   : self.filePath,
             @"recordedDate" : self.recordedDate,
             @"memoName" : self.memoName};
}


@end
