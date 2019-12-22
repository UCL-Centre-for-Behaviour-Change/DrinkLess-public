//
//  PXDebug.h
//  drinkless
//
//  Created by Hari Karam Singh on 09/02/2016.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#ifndef PXDebug_h
#define PXDebug_h

// Ensure this stay out of production
#if DEBUG

// Forces the smiley on "I am..." section
#define FORCE_DEFAULT_AVATAR_IMAGE  NO

// Set to nil for none or NSNumber (@32 style)
#define SET_GROUP_ID_ON_LAUNCH      0

#define SET_FIRST_RUN_DATE_TO_DAYS_BEFORE_NOW   0

#define RESET_SCREENS_VIEWED_COUNT_FOR_TIP   0

#define DBG_FAKE_DEMOGRAPHIC_DATA 0

// DASHBOARD TASKS (should rename TASK)
#define DBG_DASHBOARD_TASK_FORCE_RECHECK  0
#define DBG_DASHBOARD_FORCE_RANDOM        0   // Force showing of a "random" task
#define DBG_DASHBOARD_TASK_FORCE_SHOW_AUDIT      0   // Force audit follow up
#define DBG_DASHBOARD_SHOW_AUDIT_TASK_AFTER_DAYS 0  // set to 0 to default to system 28


// Comment out to disable
//#define FORCE_INTRO_STAGE PXIntroStageAuditResults


// Disabling also disables the timedate & timezone swizzle
#define ENABLE_TIME_DEBUG_PANEL     0   // See Debug.swift too!


#define logd(msg, ...) NSLog(@"[%s] DEBUG: " msg, __PRETTY_FUNCTION__, ##__VA_ARGS__)
//#define logd(msg, ...)

#else


#define logd(msg ...)

#endif





#endif /* PXDebug_h */



