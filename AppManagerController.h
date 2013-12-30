//
//  AppManagerController.h
//  iTools
//
//  Created by Jolin He on 12-11-13.
//  Copyright (c) 2012年 Jolin He. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BaseViewController.h"

@interface AppManagerController : BaseViewController
@property (weak) IBOutlet NSTabView *tabView;

@property (weak) IBOutlet NSButton *installBt;
@property (weak) IBOutlet NSButton *refreshBt;
@property (weak) IBOutlet NSTableView *appListView;

@property (weak) IBOutlet NSButton *refreshArchBt;
@property (weak) IBOutlet NSTableView *archiveListView;

- (IBAction)segmentChanged:(NSSegmentedControl*)sender;

- (IBAction)installAction:(id)sender;
- (IBAction)refrechAction:(id)sender;
- (IBAction)refreshArchAction:(id)sender;
@end
