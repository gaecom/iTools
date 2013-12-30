//
//  DeviceNode.m
//  iTools
//
//  Created by Jolin He on 12-11-14.
//  Copyright (c) 2012年 Jolin He. All rights reserved.
//

#import "DeviceNode.h"
#import "DeviceItemNode.h"
#import "InfoViewController.h"
#import "AppManagerController.h"
#import "MediaFileManagerController.h"

@implementation DeviceNode
-(id)initWithDevice:(AMDevice*)device{
    self=[super init];
    if (self) {
        _device=device;
        
        InfoViewController* ctr1=[[InfoViewController alloc] initWithNibName:@"InfoViewController" bundle:nil];
        ctr1.device=device;
        AppManagerController* ctr2=[[AppManagerController alloc] initWithNibName:@"AppManagerController" bundle:nil];
        ctr2.device=device;
        MediaFileManagerController* ctr3=[[MediaFileManagerController alloc] initWithDevice:[device newAFCMediaDirectory] device:device];
        
        _tabs=@[
        [[DeviceItemNode alloc] initWithTitle:@"设备信息" controller:ctr1],
        [[DeviceItemNode alloc] initWithTitle:@"软件管理" controller:ctr2],
        [[DeviceItemNode alloc] initWithTitle:@"文件系统" controller:ctr3],
        ];
    }
    return self;
}

-(NSString*)deviceName{
    return _device.deviceName;
}
@end
