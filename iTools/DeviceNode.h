//
//  DeviceNode.h
//  iTools
//
//  Created by Jolin He on 12-11-14.
//  Copyright (c) 2012年 Jolin He. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobileDeviceAccess.h"

@interface DeviceNode : NSObject
@property(nonatomic,readonly)AMDevice* device;
@property(nonatomic,readonly)NSArray* tabs;

-(id)initWithDevice:(AMDevice*)device;
@end
