    //
//  BLCAwesomeFloatingToolbar.m
//  BlocBrowser
//
//  Created by Greg Plumbly on 10/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXAwesomeFloatingGroupDebug.h"
#import "PXGroupsManager.h"

@interface PXAwesomeFloatingGroupDebug ()

@property (nonatomic, strong) NSArray *parameters;
@property (nonatomic, strong) UISwitch *mySwitch;
@property (nonatomic, strong) UILabel *myGroupIDLabel;
@property (nonatomic, strong) PXGroupsManager *groupsManager;

@end

@implementation PXAwesomeFloatingGroupDebug

- (instancetype) init {
    self = [super init];
    if (self) {
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panFired:)];
        [self addGestureRecognizer:panGesture];
        
        self.alpha = 0.6 ;
        
        self.parameters = @[@"highAP", @"highID", @"highAAT", @"highNM", @"highSM"];
        
        CGFloat labelX = 10;
        CGFloat labelY = 10;
        CGFloat labelHeight = 20;
        CGFloat labelWidth = 140;
        
        CGFloat switchX = 80;
        CGFloat switchY = 5;
        CGFloat switchHeight = 20;
        CGFloat switchWidth = 140;
        
        self.groupsManager = [PXGroupsManager sharedManager];
        
        for (NSInteger i = 0; i < self.parameters.count; i++) {
            NSString *parameter = self.parameters[i];
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(labelX, labelY, labelWidth, labelHeight)];
            
            label.text = [NSString stringWithFormat:@"%@: ", parameter];
            labelY += 44 ;
            
            CGRect myFrame = CGRectMake(switchX, switchY, switchWidth, switchHeight);
            
            self.mySwitch = [[UISwitch alloc] initWithFrame:myFrame];
            self.mySwitch.tag = i;
            
            NSNumber *number = [self.groupsManager valueForKey:parameter];
            NSLog(@"GROUP ID: %@", self.groupsManager.groupID);
            if (number.boolValue) {
                [self.mySwitch setOn:YES];
            }
            
            [self.mySwitch addTarget:self
                              action:@selector(switchIsChanged:)
                    forControlEvents:UIControlEventValueChanged];
            
            switchY += 44 ;
            
            [self addSubview:label];
            
            [self addSubview:self.mySwitch];
        }
        
    }
    return self;
}

- (void)switchIsChanged:(UISwitch *)paramSender {
    NSString *parameter = self.parameters[paramSender.tag];
    [self.groupsManager setValue:@(paramSender.isOn) forKey:parameter];
    self.myGroupIDLabel.text = [self.groupsManager.groupID stringValue];
}

#pragma mark - Touch Handling

- (void)panFired:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:self];
        if ([self.delegate respondsToSelector:@selector(floatingToolbar:didTryToPanWithOffset:)]) {
            [self.delegate floatingToolbar:self didTryToPanWithOffset:translation];
        }
        [recognizer setTranslation:CGPointZero inView:self];
    }
}

@end
