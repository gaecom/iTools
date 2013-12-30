//
//  MBProgressHUD.h
//  iTools
//
//  Created by Jolin He on 12-11-16.
//  Copyright (c) 2012年 Jolin He. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MBProgressHUD : NSView
@property(nonatomic,strong)NSString *text;
@property(assign) BOOL removeFromSuperViewOnHide;

+ (MBProgressHUD *)showHUDAddedTo:(NSView *)view animated:(BOOL)animated;
+ (BOOL)hideHUDForView:(NSView *)view animated:(BOOL)animated;
+ (NSUInteger)hideAllHUDsForView:(NSView *)view animated:(BOOL)animated;
+ (MBProgressHUD *)HUDForView:(NSView *)view;

- (id)initWithView:(NSView *)view;
- (void)show:(BOOL)animated;
- (void)hide:(BOOL)animated;
- (void)hide:(BOOL)animated afterDelay:(NSTimeInterval)delay;
@end
