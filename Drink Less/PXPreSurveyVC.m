//
//  PXPreSurveyVC.m
//  drinkless
//
//  Created by Brio Taliaferro on 27/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXPreSurveyVC.h"
#import "PXPreSurveyView.h"
#import "PXSurveyTVC.h"

@interface PXPreSurveyVC () <PXPreSurveyViewDelegate>

@property (nonatomic, strong) NSDictionary *surveyDictionary;

@end

@implementation PXPreSurveyVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"PXPreSurveyView"
                                                         owner:self
                                                       options:nil];
    PXPreSurveyView *surveyView = [nibContents objectAtIndex:0];
    surveyView.frame = CGRectMake(0,0,300,400); //or whatever coordinates you need
    surveyView.delegate = self;
    
    self.title = self.surveyType;
    
    NSString* filepath = [[NSBundle mainBundle] pathForResource:self.surveyType ofType:@"plist"];
    self.surveyDictionary = [[NSDictionary alloc] initWithContentsOfFile:filepath];

    surveyView.headerLabel.text = self.surveyDictionary[@"HeaderLabel"];
    surveyView.descriptionLabel.text = self.surveyDictionary[@"DescriptionLabel"];
    [self.view addSubview:surveyView];
}


-(void)preSurveyView:(PXPreSurveyView *)preSurveyView dismissedWithNumberOfDrinks:(int)numberOfDrinks intoxicationLevel:(float)intoxication {
    UIStoryboard* storyBoard = [UIStoryboard storyboardWithName:@"PXGames" bundle:nil];
    UIViewController <PXPreSurveyProtocol> *nextVC = [storyBoard instantiateViewControllerWithIdentifier:self.surveyDictionary[@"VCIdentifier"]];
        nextVC.surveyType = self.surveyType;
        nextVC.numberOfDrinks = numberOfDrinks;
        nextVC.intoxication = intoxication;
    [self.navigationController pushViewController:nextVC animated:YES];
}

@end
