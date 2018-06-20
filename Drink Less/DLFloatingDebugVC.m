//
//  DLFloatingDebugVC.m
//  drinkless
//
//  Created by Hari Karam Singh on 30/08/2017.
//  Copyright © 2017 Greg Plumbly. All rights reserved.
//

#import "DLFloatingDebugVC.h"
#import "DLDebugger.h"

@interface DLFloatingDebugVC ()

@end

@implementation DLFloatingDebugVC
{
    IBOutlet UILabel *_timeZoneLbl;
    IBOutlet UILabel *_datetimeLbl;
}

- (instancetype)init
{
    self = [super initWithNibName:@"DLFloatingDebugView" bundle:nil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    

    UIPanGestureRecognizer *panGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_handlePanGR:)];
    [self.view addGestureRecognizer:panGR];
    
    [self _updateLabels];
}


//////////////////////////////////////////////////////////
// MARK: - Event Handlers
//////////////////////////////////////////////////////////
- (IBAction)_handleTimeZoneDec:(id)sender {
#if ENABLE_TIME_DEBUG_PANEL
    [DLDebugger.sharedInstance shiftTimeZone:-1];
    [self _updateLabels];
#endif
}
- (IBAction)_handleTimeZoneInc:(id)sender {
#if ENABLE_TIME_DEBUG_PANEL
    [DLDebugger.sharedInstance shiftTimeZone:1];
    [self _updateLabels];
#endif
}

- (IBAction)_handleDateTimeDec:(id)sender {
#if ENABLE_TIME_DEBUG_PANEL
    static NSTimeInterval last;
    NSTimeInterval now = CACurrentMediaTime();
    NSInteger shift = 1;
    if ((now - last) < 0.2) {
        shift = 12;
    }
    last = now;
    [DLDebugger.sharedInstance shiftDateTimeByHours:-shift];
    [self _updateLabels];
#endif
}
- (IBAction)_handleDateTimeInc:(id)sender {
#if ENABLE_TIME_DEBUG_PANEL
    static NSTimeInterval last;
    NSTimeInterval now = CACurrentMediaTime();
    NSInteger shift = 1;
    if ((now - last) < 0.2) {
        shift = 12;
    }
    last = now;
    [DLDebugger.sharedInstance shiftDateTimeByHours:shift];
    [self _updateLabels];
#endif
}

//---------------------------------------------------------------------

/** Drag n drop */
- (void)_handlePanGR:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint offset = [recognizer translationInView:self.view];
        [recognizer setTranslation:CGPointZero inView:self.view];
        
        UIView *toolbar = recognizer.view;
        CGPoint startingPoint = toolbar.frame.origin;
        CGPoint newPoint = CGPointMake(startingPoint.x + offset.x, startingPoint.y + offset.y);
        
        CGRect potentialNewFrame = CGRectMake(newPoint.x, newPoint.y, CGRectGetWidth(toolbar.frame), CGRectGetHeight(toolbar.frame));
        
        if (CGRectContainsRect(UIApplication.sharedApplication.keyWindow.bounds, potentialNewFrame)) {
            toolbar.frame = potentialNewFrame;
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: - Additional Privates
//////////////////////////////////////////////////////////

- (void)_updateLabels
{
#if ENABLE_TIME_DEBUG_PANEL

    _timeZoneLbl.text = [NSCalendar autoupdatingCurrentCalendar].timeZone.name;
    
    _datetimeLbl.text = [NSString stringWithFormat:@"%li (%@)", DLDebugger.sharedInstance.timeHoursShift, [NSDate date]];
#endif
}


@end

