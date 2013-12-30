//
//  BaseViewController.h
//  iTools
//
//  Created by Jolin He on 12-11-14.
//  Copyright (c) 2012年 Jolin He. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MobileDeviceAccess.h"

@class DeviceItemNode;
@interface BaseViewController : NSViewController{
    AMDevice* _device;
}
@property(nonatomic,strong)AMDevice* device;
-(void)viewWillAppear;
-(void)viewWillDisAppear;
@end
