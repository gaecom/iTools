//
//  InfoViewController.h
//  iTools
//
//  Created by Jolin He on 12-11-12.
//  Copyright (c) 2012年 Jolin He. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BaseViewController.h"

@interface InfoViewController : BaseViewController
@property (weak) IBOutlet NSTextField *deviceNameLab;
@property (weak) IBOutlet NSTextField *activeStatus;
@property (weak) IBOutlet NSTextField *jailbreakStatus;
@property (weak) IBOutlet NSTextField *deviceType;
@property (weak) IBOutlet NSTextField *sellArea;
@property (weak) IBOutlet NSTextField *buyDate;
@property (weak) IBOutlet NSTextField *activeDate;
@property (weak) IBOutlet NSTextField *supportRepairDate;
@property (weak) IBOutlet NSTextField *sn;
@property (weak) IBOutlet NSTextField *systemVersion;
@property (weak) IBOutlet NSLevelIndicator *batteryStatus;
@property (weak) IBOutlet NSTextField *deviceColor;

@end
