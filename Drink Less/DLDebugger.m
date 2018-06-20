//
//  DLDebugger.m
//  drinkless
//
//  Created by Hari Karam Singh on 30/08/2017.
//  Copyright © 2017 Greg Plumbly. All rights reserved.
//

#import "DLDebugger.h"
#import "PXDebug.h"

#if ENABLE_TIME_DEBUG_PANEL

@implementation DLDebugger
{
    NSUserDefaults *_defs;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [self new];
    });
    return shared;
}

//---------------------------------------------------------------------

- (instancetype)init
{
    self = [super init];
    if (self) {
        _defs = [NSUserDefaults standardUserDefaults];
        [_defs registerDefaults:@{@"timeZoneName": NSCalendar.autoupdatingCurrentCalendar.timeZone.name,
                                  @"timeHoursShift": @0}];
        [_defs synchronize];
        
        // Initialise system parameters to our stored values
        [NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneWithName:self.timeZoneName]];
        
    }
    return self;
}

//---------------------------------------------------------------------

- (NSString *)timeZoneName { return [_defs objectForKey:@"timeZoneName"]; }
- (void)setTimeZoneName:(NSString *)value {
    [_defs setObject:value forKey:@"timeZoneName"];
    [_defs synchronize];
}


- (NSInteger)timeHoursShift { return [_defs integerForKey:@"timeHoursShift"]; }
- (void)setTimeHoursShift:(NSInteger)value {
    [_defs setInteger:value forKey:@"timeHoursShift"];
    [_defs synchronize];
}

//////////////////////////////////////////////////////////
// MARK: - Public Methods
//////////////////////////////////////////////////////////

- (void)shiftTimeZone:(NSInteger)shift {
    //NSArray *tzs = NSTimeZone.knownTimeZoneNames;
    NSArray *tzs = @[@"America/Los_Angeles", @"America/New_York", @"Europe/London", @"Europe/Paris", @"Europe/Minsk", @"Asia/Calcutta"];
    
    // Get the index of the curent tz and shift
    NSString *tzName = NSCalendar.autoupdatingCurrentCalendar.timeZone.name;
    if (![self.timeZoneName isEqualToString:tzName]) {
        NSLog(@"WARN: Debug TZ %@ != Calendar TZ %@", tzName, DLDebugger.sharedInstance.timeZoneName);
    }
    NSInteger idx = [tzs indexOfObject:tzName];
    if (idx == NSNotFound) {
        NSLog(@"ERROR: Time Zone %@ not found", tzName);
        idx = 0;
        shift = 0;
    }
    // Wrap
    idx += shift;
    while (idx < 0) {
        idx += tzs.count;
    }
    idx %= tzs.count;
    
    // Set new time zone
    self.timeZoneName = tzs[idx];
    [NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneWithName:tzs[idx]]];

}

//---------------------------------------------------------------------

- (void)shiftDateTimeByHours:(NSInteger)shift {
    self.timeHoursShift += shift;
}

@end

#endif 
