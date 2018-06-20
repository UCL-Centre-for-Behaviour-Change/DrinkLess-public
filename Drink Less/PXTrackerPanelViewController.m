//
//  PXTrackerPanelViewController.m
//  drinkless
//
//  Created by Edward Warrender on 05/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXTrackerPanelViewController.h"
#import "UIImageEffects.h"
#import "PXDailyTaskManager.h"

@interface PXTrackerPanelViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomLayoutConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIView *panelView;
@property (strong, nonatomic) UIViewController *selectedViewController;
@property (strong, nonatomic) UIViewController *drinksViewController;
@property (strong, nonatomic) UIViewController *calendarViewController;
@property (nonatomic, getter = isOpen) BOOL open;
@property (strong, nonatomic) IBOutlet UIPanGestureRecognizer *panGR;
@property (nonatomic) CGPoint dragInitialTouchPt;

@end

@implementation PXTrackerPanelViewController
{
}

+ (instancetype)viewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"DrinksTracker" bundle:nil];
    return [storyboard instantiateInitialViewController];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Drinks panel";
    
    if (!self.referenceDate) {
        self.referenceDate = [NSDate strictDateFromToday];
    }
    self.datePicking = NO;
    
    [self.panGR addTarget:self action:@selector(handlePanGesture:)];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)panGR
{
    if (panGR.state == UIGestureRecognizerStateBegan) {
    }
    
    static const CGFloat SNAP = 10;
    
    CGFloat deltaY = [panGR translationInView:self.view].y;
    deltaY = MAX(deltaY, 0);
//    if (deltaY < 5) deltaY = 0;
    
    CGFloat initY = self.view.frame.size.height - self.panelView.frame.size.height;
    CGRect newFrame = self.panelView.frame;
    newFrame.origin.y = initY + deltaY;
    self.panelView.frame = newFrame;
    
    if (panGR.state == UIGestureRecognizerStateEnded ||
        panGR.state == UIGestureRecognizerStateCancelled ||
        panGR.state == UIGestureRecognizerStateCancelled) { // jic
        
        // Set open or closed
        if (deltaY > SNAP) {
            __weak typeof(self) wself = self;
            [self setOpen:NO animated:YES completion:^{
                [wself.delegate didCompleteCloseAfterDrag];
            }];
        } else {
            [self setOpen:YES animated:YES completion:nil];
        }
    }
    
//    NSLog(@"%i: %.1f %.1f", panGR.state, .x, [panGR locationInView:self.view.superview].y);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self refreshScreenshot];
}

- (void)refreshScreenshot {
    self.view.hidden = YES;
    UIView *superview = self.view.superview;
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, YES, 0.0);
    [superview drawViewHierarchyInRect:superview.bounds afterScreenUpdates:YES];
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.view.hidden = NO;
    self.backgroundImageView.image = [UIImageEffects imageByApplyingBlurToImage:screenshot
                                                                     withRadius:10.0
                                                                      tintColor:[UIColor colorWithWhite:0.0 alpha:0.4]
                                                          saturationDeltaFactor:1.0
                                                                      maskImage:nil];
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];

    if (parent) {
        [self refreshScreenshot];
        [self setOpen:NO animated:NO completion:NULL];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    id viewController = segue.destinationViewController;
    
    if ([segue.identifier isEqualToString:@"embedDrinks"]) {
        self.drinksViewController = viewController;
    } else if ([segue.identifier isEqualToString:@"embedCalendar"]) {
        self.calendarViewController = viewController;
    }
}

#pragma mark - Properties

- (void)setDatePicking:(BOOL)datePicking {
    _datePicking = datePicking;
    
    self.selectedViewController = datePicking ? self.calendarViewController : self.drinksViewController;
}

- (void)setSelectedViewController:(UIViewController *)selectedViewController {
    _selectedViewController = selectedViewController;
    
    if ([selectedViewController conformsToProtocol:@protocol(PXTrackerPanelChild)]) {
        id <PXTrackerPanelChild> child = (id<PXTrackerPanelChild>)selectedViewController;
        child.panelViewController = self;
        child.referenceDate = self.referenceDate;
    }
    self.drinksViewController.view.superview.hidden = selectedViewController != self.drinksViewController;
    self.calendarViewController.view.superview.hidden = selectedViewController != self.calendarViewController;
}

#pragma mark - Actions

- (IBAction)tappedBackground:(id)sender {
    [self.delegate shouldClosePanel];
}

- (void)setOpen:(BOOL)open animated:(BOOL)animated completion:(void (^)(void))completion {
    _open = open;
    
    if (open) {
        self.bottomLayoutConstraint.constant = 0.0;
    } else {
        self.bottomLayoutConstraint.constant = -self.panelView.frame.size.height;
    }
    
    void (^updateBlock)() = ^{
        [self.panelView setNeedsLayout];
        [self.panelView layoutIfNeeded];
        self.backgroundImageView.alpha = open;
    };
    if (animated) {
        NSTimeInterval duration = open ? 0.5 : 0.8;
        [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.0 options:0 animations:updateBlock completion:^(BOOL finished) {
            if (completion) completion();
        }];
    } else {
        updateBlock();
    }
}

@end
