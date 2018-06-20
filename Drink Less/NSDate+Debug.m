//
//  NSDate+Debug.m
//  drinkless
//
//  Created by Hari Karam Singh on 30/08/2017.
//  Copyright © 2017 Greg Plumbly. All rights reserved.
//

#import "NSDate+Debug.h"
#import <objc/runtime.h>
#import "DLDebugger.h"

@implementation NSDate(Debug)

#if DEBUG && ENABLE_TIME_DEBUG_PANEL

+ (NSDate *)dateSwiz {
    NSDate *d = [NSDate dateSwiz];
    // Shift by the hours in debug
    return [d dateByAddingTimeInterval:(NSTimeInterval)DLDebugger.sharedInstance.timeHoursShift * 3600.0];
}

+ (void)initialize
{

    SEL orig = @selector(date);
    SEL new = @selector(dateSwiz);
    Method origMethod = class_getClassMethod(self, orig);
    Method newMethod = class_getClassMethod(self, new);
    
    Class c = object_getClass((id)self);
    
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
        method_exchangeImplementations(origMethod, newMethod);
}

#endif

@end
