//
//  PXCustomView.m
//  drinkless
//
//  Created by Artsiom Khitryk on 4/4/16.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import "PXCustomView.h"

@implementation PXCustomView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        [self loadNib];
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        [self loadNib];
        [self setup];
    }
    return self;
}

- (void)loadNib
{
    //    LOG(@"CLASS: %@", NSStringFromClass([self class]));
    NSArray *objects = [[NSBundle bundleForClass:[self class]]
                        loadNibNamed:NSStringFromClass([self class])
                        owner:self
                        options:nil];
    
    self.contentView = objects.firstObject;
    //    LOG(@"%@ ContView: %@", NSStringFromClass([self class]), self.contentView);
    [self addSubview:self.contentView];
    self.contentView.frame = self.bounds;
    [self viewDidLoad];
}

- (void)setup
{}

- (void)viewDidLoad
{}

@end
