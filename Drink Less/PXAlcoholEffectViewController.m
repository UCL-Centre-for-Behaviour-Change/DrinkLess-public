//
//  PXAlcoholEffectViewController.m
//  drinkless
//
//  Created by Edward Warrender on 03/02/2015.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXAlcoholEffectViewController.h"
#import "PXBarPlot.h"
#import "PXAllStatistics.h"
#import "CorePlot-CocoaTouch.h"
#import "UITextView+HTML.h"

@interface PXAlcoholEffectViewController ()

@property (nonatomic) PXAlcoholEffectType effectType;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UITextView *explanationTextView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) PXBarPlot *barPlot;

@end

@implementation PXAlcoholEffectViewController

- (instancetype)initWithEffectType:(PXAlcoholEffectType)effectType {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Activities" bundle:nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"PXAlcoholEffectVC"];
    if (self) {
        _effectType = effectType;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Alcohol Effect";
    
    CPTGraphHostingView *hostingView = [[CPTGraphHostingView alloc] init];
    hostingView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:hostingView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(hostingView);
    NSDictionary *metrics = @{@"margin": @5.0};
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[hostingView]|" options:0 metrics:nil views:views]];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[hostingView(270)]-margin-|" options:0 metrics:metrics views:views]];
    self.barPlot = [[PXBarPlot alloc] initWithHostingView:hostingView];
}

- (void)setAlcoholEffects:(PXAlcoholEffects *)alcoholEffects {
    _alcoholEffects = alcoholEffects;
    
    NSNumber *effectAfterDrinking = alcoholEffects.afterDrinking[@(self.effectType)];
    NSNumber *effectAfterNotDrinking = alcoholEffects.afterNotDrinking[@(self.effectType)];
    self.barPlot.plotData = @[@{@"x": @0,
                                @"y": effectAfterNotDrinking,
                                PXTitleKey: @"Light or no drinking days",
                                PXPlotIdentifier:@(1)},
                              @{@"x": @1,
                                @"y": effectAfterDrinking,
                                PXTitleKey: @"Heavy drinking days",
                                PXPlotIdentifier:@(2)}
                              ];
    
    [self.barPlot setXTitle:nil yTitle:@"Score" xKey:@"x" yKey:@"y" minYValue:0.0 maxYValue:10.0 goalValue:0.0 consumptionType:PXConsumptionTypeMoodScore showLegend:NO];

    self.barPlot.plots = @[@{PXPlotIdentifier:@(1), PXColorKey: [UIColor drinkLessGreenColor]}, @{PXPlotIdentifier:@(2), PXColorKey: [UIColor goalRedColor]}];
    
    NSDictionary *effects = alcoholEffects.information[self.effectType];
    NSString *effectTitle = effects[@"title"];
    self.headerLabel.text = [NSString stringWithFormat:@"Your average %@ score on:", effectTitle.lowercaseString];
    [self.explanationTextView loadHTMLString:effects[@"html"]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
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

@end
