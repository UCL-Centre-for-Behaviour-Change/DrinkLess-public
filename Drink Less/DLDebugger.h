//
//  DLDebugger.h
//  drinkless
//
//  Created by Hari Karam Singh on 30/08/2017.
//  Copyright © 2017 Greg Plumbly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PXDebug.h"

#if ENABLE_TIME_DEBUG_PANEL

// Persisent
@interface DLDebugger : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, strong) NSString *timeZoneName;
@property (nonatomic) NSInteger timeHoursShift;

- (void)shiftTimeZone:(NSInteger)shift;
- (void)shiftDateTimeByHours:(NSInteger)shift;
@end

#endif
