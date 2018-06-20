//
//  BLCAwesomeFloatingToolbar.h
//  BlocBrowser
//
//  Created by Greg Plumbly on 10/11/2014.
//  Copyright (c) 2016 UCL. All rights reserved.
//  @license See LICENSE.txt
//

#import <UIKit/UIKit.h>

@class PXAwesomeFloatingGroupDebug;

@protocol PXAwesomeFloatingGroupDebugDelegate <NSObject>

@optional

- (void) floatingToolbar:(PXAwesomeFloatingGroupDebug *)toolbar didTryToPanWithOffset:(CGPoint)offset;

@end

@interface PXAwesomeFloatingGroupDebug : UIView

@property (nonatomic, weak) id <PXAwesomeFloatingGroupDebugDelegate> delegate;
@property (nonatomic) CGRect initialFrame ;


@end
