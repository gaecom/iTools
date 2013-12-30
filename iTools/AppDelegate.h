//
//  AppDelegate.h
//  iTools
//
//  Created by Jolin He on 12-11-9.
//  Copyright (c) 2012年 Jolin He. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate,NSTableViewDelegate,NSWindowDelegate>
@property (weak) IBOutlet NSOutlineView *outlineView;
@property (weak) IBOutlet NSView *welcomeView;
@property (weak) IBOutlet NSSplitView *splitView;
@property (assign) IBOutlet NSWindow *window;
@end
