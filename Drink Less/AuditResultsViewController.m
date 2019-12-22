//
//  AuditResultsViewController.m
//  Drink Less
//
//  Created by Greg Plumbly on 29/08/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "AuditResultsViewController.h"
#import "PXIntroManager.h"
#import "drinkless-Swift.h"

static NSString *const PXAuditScoreKey = @"score";
static NSString *const PXBoundaryKey = @"boundary";
static NSString *const PXColorKey = @"color";
static NSString *const PXIndicationKey = @"indication";
static NSString *const PXNoteKey = @"note";

@interface AuditResultsViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *indicationLabel;
@property (weak, nonatomic) IBOutlet UILabel *bodyLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonContainerConstraint;
@property (nonatomic) CGFloat originalButtonContainerHeight;
@property (strong, nonatomic, readonly) NSArray *allInformation;
@property (strong, nonatomic) PXIntroManager *introManager;
@property (nonatomic, getter = hasAnimatedOnce) BOOL animatedOnce;
@property (nonatomic) BOOL isOnboarding;
@property (nonatomic, strong) AuditData *auditData;

@end

@implementation AuditResultsViewController

+ (instancetype)auditResultsViewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    return [storyboard instantiateViewControllerWithIdentifier:@"PXIntroVC2"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.auditData = VCInjector.shared.workingAuditData;
    self.isOnboarding = VCInjector.shared.isOnboarding;
    self.introManager = [PXIntroManager sharedManager];

    self.originalButtonContainerHeight = self.buttonContainerConstraint.constant;
    self.buttonContainerHidden = self.isButtonContainerHidden;
    
    self.navigationItem.hidesBackButton = YES;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PXHideProgressToolbar" object:nil userInfo:nil];
    
    [self loadInformation];
    
    NSInteger auditScore = self.auditData.isFollowUp ? self.auditData.auditCScore : self.auditData.auditScore;
    NSParameterAssert(auditScore >= 0);
    NSDictionary *information = [self informationForAuditScore:auditScore];
    UIColor *color = information[PXColorKey];
    
    self.indicationLabel.text = information[PXIndicationKey];
    self.indicationLabel.textColor = color;
    
    NSMutableString *body = [NSMutableString string];
    [body appendFormat:@"Your score was %li which lies in the range of %@ for this risk zone.", auditScore, information[PXBoundaryKey]];
    NSString *note = information[PXNoteKey];
    if (note) {
        [body appendFormat:@" %@", note];
    }
    [body appendString:@"\n\nThis score tells you about your drinking in the past. We’ll ask you the same questions again in a month so you can see what has changed."];
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:body];
    
//    if (auditScore) {
        NSRange scoreRange = [body rangeOfString:@(auditScore).stringValue];
        NSDictionary *highlightedAttributes = @{NSForegroundColorAttributeName: color};
        [attributedText addAttributes:highlightedAttributes range:scoreRange];
        self.bodyLabel.attributedText = attributedText;
//    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.hasAnimatedOnce) {
        self.titleLabel.alpha = 0.0;
        self.indicationLabel.alpha = 0.0;
        self.bodyLabel.alpha = 0.0;
    }
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (Debug.ENABLED && Debug.ONBOARDING_STEP_THROUGH_TO != nil && ![Debug.ONBOARDING_STEP_THROUGH_TO isEqualToString:@"audit-results"]) {
        [self tappedContinue:nil];
    }
    
    
    if (!self.hasAnimatedOnce) {
        self.animatedOnce = YES;
        
        CGRect indicationEndFrame = self.indicationLabel.frame;
        CGRect indicationStartFrame = indicationEndFrame;
        indicationStartFrame.origin.y = self.titleLabel.frame.origin.y;
        self.indicationLabel.frame = indicationStartFrame;
        
        [UIView animateWithDuration:1.25 delay:0.5 usingSpringWithDamping:0.6 initialSpringVelocity:0.0 options:0 animations:^{
            self.indicationLabel.frame = indicationEndFrame;
        } completion:nil];
        
        [UIView animateWithDuration:0.5 animations:^{
            self.titleLabel.alpha = 1.0;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5 animations:^{
                self.indicationLabel.alpha = 1.0;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.8 animations:^{
                    self.bodyLabel.alpha = 1.0;
                }];
            }];
        }];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self.scrollView setNeedsLayout];
    [self.scrollView layoutIfNeeded];
    
    // Center the scrollView vertically if the content size height has changed
    CGFloat height = self.scrollView.contentSize.height;
    CGFloat verticalSpace = self.scrollView.bounds.size.height - height;
    if (verticalSpace > 0) {
        self.scrollView.contentInset = UIEdgeInsetsMake(verticalSpace * 0.5, 0.0, 0.0, 0.0);
        self.scrollView.scrollEnabled = NO;
    } else {
        self.scrollView.contentInset = UIEdgeInsetsZero;
        self.scrollView.scrollEnabled = YES;
    }
}

- (NSDictionary *)informationForAuditScore:(NSInteger)auditScore {
    NSDictionary *information = nil;
    for (NSDictionary *dictionary in self.allInformation) {
        NSInteger score = [dictionary[PXAuditScoreKey] integerValue];
        if (auditScore >= score) {
            information = dictionary;
        } else {
            break;
        }
    }
    return information;
}

- (void)loadInformation {
    _allInformation = @[@{PXAuditScoreKey: @0,
                          PXBoundaryKey: @"0-7",
                          PXColorKey: [UIColor gaugeGreenColor],
                          PXIndicationKey: @"Your results indicate you’re at low risk of alcohol-related harm provided you’re also drinking 14 units or less a week.",
                          PXNoteKey: @"You are in the lowest of the four risk zones (low risk; increasing risk; higher risk; and at risk of alcohol dependence)."
                          },
                        
                        @{PXAuditScoreKey: @8,
                          PXBoundaryKey: @"8-15",
                          PXColorKey: [UIColor gaugeDarkYellowColor],
                          PXIndicationKey: @"Your results indicate you’re at increasing risk of alcohol-related harm.",
                          PXNoteKey: @"You are in the second of the four risk zones (low risk; increasing risk; higher risk; and at risk of alcohol dependence)."
                          },
                        
                        @{PXAuditScoreKey: @16,
                          PXBoundaryKey: @"16-19",
                          PXColorKey: [UIColor gaugeOrangeColor],
                          PXIndicationKey: @"Your results indicate you’re at higher risk of alcohol-related harm.",
                          PXNoteKey: @"You are in the second highest of the four risk zones (low risk; increasing risk; higher risk; and at risk of alcohol dependence)."
                          },
                        
                        @{PXAuditScoreKey: @20,
                          PXBoundaryKey: @"20-40",
                          PXColorKey: [UIColor gaugeRedColor],
                          PXIndicationKey: @"Your results indicate the possibility of alcohol dependence. You are welcome to continue to use this app though we strongly advise you to contact your GP for further support.",
                          PXNoteKey: @" You are in the highest of the four risk zones (low risk; increasing risk; higher risk; and at risk of alcohol dependence)."}];
}

#pragma mark - Properties

- (void)setButtonContainerHidden:(BOOL)buttonContainerHidden {
    _buttonContainerHidden = buttonContainerHidden;
    
    if (self.isViewLoaded) {
        self.buttonContainerConstraint.constant = buttonContainerHidden ? 0 : self.originalButtonContainerHeight;
    }
}

#pragma mark - Actions

- (IBAction)tappedContinue:(id)sender {
    NSAssert(self.isOnboarding, @"Should only be shown on onboarding!");
    
    self.introManager.stage = PXIntroStageAboutYou;
    [self.introManager save];
    [self performSegueWithIdentifier:@"PXShowAboutYou" sender:nil];
}

@end
