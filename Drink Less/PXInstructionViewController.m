//
//  PXInstructionViewController.m
//  drinkless
//
//  Created by Edward Warrender on 03/10/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXInstructionViewController.h"
#import "PXTutorialView.h"

@interface PXInstructionViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation PXInstructionViewController

- (instancetype)initWithDemo:(BOOL)demo {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PXGames" bundle:nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"informationVC"];
    if (self) {
        if (demo) {
            _tutorialView = [[PXTutorialView alloc] initWithFrame:self.view.bounds];
            _tutorialView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.view insertSubview:_tutorialView belowSubview:_textView];
        }
    }
    return self;
}

+ (instancetype)instructionWithDemo:(BOOL)demo {
    return [[self alloc] initWithDemo:demo];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.screenName = @"Instruction";
    
    self.textView.textContainer.lineFragmentPadding = 15.0;
    self.textView.text = self.text;
    
    if ([self.identifier isEqualToString:@"about"]) {
        self.textView.textAlignment = NSTextAlignmentLeft;
    }
}

- (void)setCards:(NSArray *)cards {
    self.tutorialView.cards = cards;
    _cards = cards;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.tutorialView.hasEndedRound) {
        [self.tutorialView startRoundWithCompletion:NULL];
    }
}

- (void)setText:(NSString *)text {
    if (self.isViewLoaded) {
        self.textView.text = text;
    }
    _text = text;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (self.tutorialView) {
        // Aligned to top
        self.textView.contentInset = UIEdgeInsetsZero;
    } else {
        // Center the text vertically if the height has changed
        // Calculate textView height instead of using content size as it doesn't work correctly
        CGFloat height = [self.textView sizeThatFits:CGSizeMake(self.textView.frame.size.width, MAXFLOAT)].height;
        CGFloat verticalSpace = self.textView.bounds.size.height - height;
        if (verticalSpace > 0) {
            self.textView.contentInset = UIEdgeInsetsMake(verticalSpace * 0.5, 0.0, 0.0, 0.0);
        } else {
            self.textView.contentInset = UIEdgeInsetsZero;
        }
    }
}

@end
