//
//  AppViewController.h
//  iTools
//
//  Created by Jolin He on 13-12-26.
//  Copyright (c) 2013年 Jolin He. All rights reserved.
//

#import "BaseViewController.h"
#import "FileSystemNode.h"
#import "MobileDeviceAccess.h"

@interface AppFileManagerController : NSWindowController{
    IBOutlet __weak NSBrowser *_browser;
}
- (IBAction)closeAction:(id)sender;
-(instancetype)initWithApplication:(AMApplication*)app device:(AMDevice*)device;
@end
